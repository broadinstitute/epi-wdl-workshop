#!/usr/bin/env sh

set -e

export PROJECT=$1

user_name() {
  gcloud config list --format 'value(core.account.split("@").slice(0))'
}

SERVICE_ACCOUNT=${2:-"cromwell-$(user_name)"}

### Set up Google Project

gcloud config set project ${PROJECT}

enable_api() {
  gcloud services enable "$1"
}

enable_api compute
enable_api genomics

### Create Cromwell executions bucket if it doesn't exist

export BUCKET=${3:-"${PROJECT}-cromwell-executions"}
REGION=${4:-"us-east1"}

gsutil mb -l "${REGION}" "gs://${BUCKET}" 2>/dev/null || true

### Generate Cromwell Pet Service Account with the necessary roles and a key

# Create SA if it doesn't exist

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT}@${PROJECT}.iam.gserviceaccount.com"

get_account() {
  gcloud iam service-accounts describe "$1" 2>/dev/null
}

if [ -z "$(get_account ${SERVICE_ACCOUNT_EMAIL})" ]; then
  gcloud iam service-accounts create "${SERVICE_ACCOUNT}" \
    --display-name "${SERVICE_ACCOUNT}"
fi

# Add roles

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

for key_id in $(get_keys); do
  gcloud iam service-accounts keys delete "${key_id}" \
    --iam-account "${SERVICE_ACCOUNT_EMAIL}"
done

export KEY_FILE="key.json"

gcloud iam service-accounts keys create "${KEY_FILE}" \
  --iam-account "${SERVICE_ACCOUNT_EMAIL}"

./generate_options.py "${PROJECT}" "${BUCKET}" "${KEY_FILE}"

rm "${KEY_FILE}"
