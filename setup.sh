#!/usr/bin/env sh

set -e

### Set up Google project

get_project() {
  gcloud config list --format 'value(core.project)'
}

PROJECT=${1:-"$(get_project)"}

enable_api() {
  gcloud services enable "$1"
}

enable_api compute
enable_api genomics

### Generate Cromwell Pet Service Account with the necessary roles and a key

# Create SA if it doesn't exist

username() {
  gcloud config list --format 'value(core.account.split("@").slice(0))'
}

SERVICE_ACCOUNT=${2:-"cromwell-$(username)"}

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT}@${PROJECT}.iam.gserviceaccount.com"

gcloud iam service-accounts create "${SERVICE_ACCOUNT}" \
  --display-name "${SERVICE_ACCOUNT}" 2>/dev/null || true

# Add roles required by CaaS

add_role() {
  gcloud projects add-iam-policy-binding "${PROJECT}" \
    --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role "roles/$1" >/dev/null
}

add_role compute.instanceAdmin.v1
add_role genomics.pipelinesRunner
add_role iam.serviceAccountUser
add_role serviceusage.serviceUsageConsumer
add_role storage.objectAdmin

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

rm "${KEY_FILE}"

### Create Cromwell executions bucket if it doesn't exist

BUCKET=${3:-"${PROJECT}-cromwell-executions"}
REGION=${4:-"us-east1"}

gsutil mb -l "${REGION}" "gs://${BUCKET}" 2>/dev/null || true
