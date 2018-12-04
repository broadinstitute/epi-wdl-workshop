#!/usr/bin/env bash

set -e

### Remember the working directory and switch to the scripts directory

pushd $(dirname "$0") >/dev/null

### Set up Google project

PROJECT=$1
REGION=$2
SAM=$3

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

SERVICE_ACCOUNT="${USER_EMAIL%@*}-cromwell-pet"
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
add_role storage.objectAdmin

PROJECT_ID=$(gcloud projects describe "${PROJECT}" --format 'value(projectNumber)')

gcloud iam service-accounts add-iam-policy-binding \
  "${PROJECT_ID}-compute@developer.gserviceaccount.com" \
  --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role "roles/iam.serviceAccountUser" >/dev/null

# (Re-)generate the key and populate it into options.json

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

./generate_options.py "${PROJECT}" "${BUCKET}" "${KEY_FILE}"

# Register SA in Sam (if not yet registered)
# so we could add it to Epi users' FireCloud group
# (which provides read access to prod data)

TOKEN=$(./get_access_token.py "${KEY_FILE}")

curl -sX POST "https://${SAM}/register/user/v1" \
  -H "Authorization: Bearer ${TOKEN}" >/dev/null

### Clean up and return to the working directory

rm "${KEY_FILE}"

popd >/dev/null
