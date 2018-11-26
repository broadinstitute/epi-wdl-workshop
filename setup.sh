#!/usr/bin/env bash

set -e

### Set up Google project

if type "gcloud.cmd" &>/dev/null; then
  export GCLOUD="gcloud.cmd"
else
  export GCLOUD="gcloud"
fi

get_project() {
  $GCLOUD config list --format 'value(core.project)'
}

PROJECT=${1:-"$(get_project)"}

enable_api() {
  $GCLOUD services enable "$1"
}

enable_api compute
enable_api genomics

### Create Cromwell executions bucket if it doesn't exist

BUCKET=${3:-"${PROJECT}-cromwell"}
REGION=${4:-"us-east1"}

if type "gsutil.cmd" &>/dev/null; then
  export GSUTIL="gsutil.cmd"
else
  export GSUTIL="gsutil"
fi

$GSUTIL mb -l "${REGION}" "gs://${BUCKET}" 2>/dev/null || true
$GSUTIL cp monitoring.sh "gs://${BUCKET}/scripts/"

### Generate Cromwell Pet Service Account with the necessary roles and a key

# Create SA if it doesn't exist

username() {
  $GCLOUD config list --format 'value(core.account.split("@").slice(0))'
}

SERVICE_ACCOUNT=${2:-"cromwell-$(username)"}

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT}@${PROJECT}.iam.gserviceaccount.com"

$GCLOUD iam service-accounts create "${SERVICE_ACCOUNT}" \
  --display-name "${SERVICE_ACCOUNT}" 2>/dev/null || true

# Add roles and permissions required by Cromwell

add_role() {
  $GCLOUD projects add-iam-policy-binding "${PROJECT}" \
    --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role "roles/$1" >/dev/null
}

add_role compute.instanceAdmin.v1
add_role genomics.pipelinesRunner
add_role storage.objectAdmin

PROJECT_ID=$($GCLOUD projects describe "${PROJECT}" --format 'value(projectNumber)')

$GCLOUD iam service-accounts add-iam-policy-binding \
  "${PROJECT_ID}-compute@developer.gserviceaccount.com" \
  --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role "roles/iam.serviceAccountUser" >/dev/null

# (Re-)generate the key and populate it into options.json

get_keys() {
  $GCLOUD iam service-accounts keys list \
    --iam-account "$1" \
    --managed-by user \
    --format 'value(name)'
}

for key_id in $(get_keys "${SERVICE_ACCOUNT_EMAIL}"); do
  $GCLOUD iam service-accounts keys delete "${key_id}" \
    --iam-account "${SERVICE_ACCOUNT_EMAIL}" -q
done

KEY_FILE="key.json"

$GCLOUD iam service-accounts keys create "${KEY_FILE}" \
  --iam-account "${SERVICE_ACCOUNT_EMAIL}"

./generate_options.py "${PROJECT}" "${BUCKET}" "${KEY_FILE}"

rm "${KEY_FILE}"

### Register user email in Sam/FireCloud (if not yet registered)

SAM="sam.dsde-prod.broadinstitute.org"

curl -sX POST "https://${SAM}/register/user/v1" \
   -H "Authorization: Bearer $($GCLOUD auth print-access-token)" >/dev/null
