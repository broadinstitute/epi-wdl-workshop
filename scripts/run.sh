#!/usr/bin/env bash

PROJECT="$1"
WDL="$2"
INPUTS="$3"

if [ "$#" -lt 3 ]; then
  echo
  echo "Please specify arguments in the following order:"
  echo "  <google_project_id> <workflow.wdl> <inputs.json>"
  echo
  echo "where <workflow.wdl> and <inputs.json>"
  echo "are either in the current working directory,"
  echo "or on the absolute path in the container"
  echo "(e.g. /example/Alignment.wdl /example/alignment.inputs.json)"
  echo
fi

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
SCRIPTS=$(dirname "$0")

if [ ! -f "${OPTIONS}" ]; then
  "${SCRIPTS}/setup.sh"
  mv "options.json" "${OPTIONS}"
fi

"${SCRIPTS}/submit.sh" "${OPTIONS}" "${WDL}" "${INPUTS}"
