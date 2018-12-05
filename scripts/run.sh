#!/usr/bin/env bash

set -e

PROJECT="$1"
WDL="$2"
INPUTS="$3"
COLLECTION="$4"

if [ "$#" -lt 3 ]; then
  echo
  echo "Please specify arguments in the following order:"
  echo "  <google_project_id> <workflow.wdl> <inputs.json> (<workflow_collection>)"
  echo
  echo "where <workflow.wdl> and <inputs.json>"
  echo "are either in the current working directory,"
  echo "or on the absolute path in the container"
  echo "(e.g. /example/Alignment.wdl /example/alignment.inputs.json)"
  echo
  echo "optionally, specify <workflow_collection> if provided"
  echo
  exit 1
fi

export CLOUDSDK_CONFIG=/cromwell

get_account() {
  gcloud auth list --format 'value([account])'
}

if [ -z "$(get_account)" ]; then
  gcloud auth login
fi

get_project() {
  gcloud config list --format 'value(core.project)'
}

if [ "$(get_project)" != "${PROJECT}" ]; then
  gcloud config set project "${PROJECT}"
fi

OPTIONS="${CLOUDSDK_CONFIG}/options-${PROJECT}.json"
SCRIPTS_DIR=$(dirname "$0")

if [ ! -f "${OPTIONS}" ]; then
  "${SCRIPTS_DIR}/setup.sh" "${PROJECT}" "${GCS_REGION}" "${SAM_HOST}"
  mv "${SCRIPTS_DIR}/options.json" "${OPTIONS}"
fi

"${SCRIPTS_DIR}/validate.sh" "${WDL}" "${INPUTS}"
"${SCRIPTS_DIR}/submit.sh" "${CROMWELL_HOST}" "${OPTIONS}" "${WDL}" "${INPUTS}" "${COLLECTION}"
