#!/usr/bin/env bash

set -e

### Remember the working directory and switch to the scripts directory

pushd $(dirname "$0") >/dev/null

### Set up Google project

PROJECT="$1"
REGION="$2"
SAM="$3"
ADMIN_GROUP="$4"
USER_COLLECTION="$5"

enable_api() {
  gcloud services enable "$1"
}

enable_api compute
enable_api genomics

### Create Cromwell executions bucket if it doesn't exist

BUCKET="${PROJECT}-cromwell"

gsutil mb -l "${REGION}" "gs://${BUCKET}" 2>/dev/null || true
gsutil cp monitoring.sh "gs://${BUCKET}/scripts/"

### Generate Cromwell user service account with the necessary roles and a key

# Create SA if it doesn't exist

USER_EMAIL=$(gcloud config get-value account)
USERNAME="${USER_EMAIL%@*}"

SERVICE_ACCOUNT="${USERNAME}-cromwell-pet"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT}@${PROJECT}.iam.gserviceaccount.com"

gcloud iam service-accounts create "${SERVICE_ACCOUNT}" \
  --display-name "Cromwell pet service account for ${USER_EMAIL}" \
  2>/dev/null || true

# Add roles and permissions required by Cromwell

add_role() {
  gcloud projects add-iam-policy-binding "${PROJECT}" \
    --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role "roles/$1" >/dev/null
}

add_role compute.instanceAdmin.v1
add_role genomics.pipelinesRunner
add_role serviceusage.serviceUsageConsumer
add_role storage.objectAdmin

gcloud iam service-accounts add-iam-policy-binding \
  "${SERVICE_ACCOUNT_EMAIL}" \
  --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role "roles/iam.serviceAccountUser" >/dev/null

# (Re-)generate the key

get_keys() {
  gcloud iam service-accounts keys list \
    --iam-account "$1" \
    --managed-by user \
    --format 'value(name)'
}

for key_id in $(get_keys "${SERVICE_ACCOUNT_EMAIL}"); do
  gcloud iam service-accounts keys delete "${key_id}" \
    --iam-account "${SERVICE_ACCOUNT_EMAIL}" -q
done

KEY_FILE="key.json"

gcloud iam service-accounts keys create "${KEY_FILE}" \
  --iam-account "${SERVICE_ACCOUNT_EMAIL}"

# Register SA in Sam (if not yet registered)
# so we could add it to Epi users' FireCloud group
# (which provides read access to prod data)

http() {
  echo $@ 1>&2
  curl -sH "Authorization: Bearer ${TOKEN}" -X "$@"
  printf "\n\n" 1>&2
}

TOKEN=$(./get_access_token.py "${KEY_FILE}")
http POST "https://${SAM}/register/user/v1"

# create a CaaS collection for the user (if it doesn't exist)
TOKEN=$(gcloud auth print-access-token)
http POST "https://${SAM}/api/resources/v1/workflow-collection/${USER_COLLECTION}"

# add admin group to collection owners
http PUT "https://${SAM}/api/resources/v1/workflow-collection/${USER_COLLECTION}/policies/owner/memberEmails/${ADMIN_GROUP}"

# Generate options.json

./generate_options.py "${PROJECT}" "${BUCKET}" "${KEY_FILE}"

### Clean up and return to the working directory

rm "${KEY_FILE}"

popd >/dev/null
