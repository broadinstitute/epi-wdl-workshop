#!/usr/bin/env bash

CROMWELL="$1"
OPTIONS="$2"
SOURCE="$3"
INPUTS="$4"
LABELS="$5"
COLLECTION="$6"

curl -s "https://${CROMWELL}/api/workflows/v1" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -F workflowOptions=@"${OPTIONS}" \
    -F workflowSource=@"${SOURCE}" \
    -F workflowInputs=@"${INPUTS}" \
    -F labels=@"${LABELS}" \
    -F collectionName="${COLLECTION}"
