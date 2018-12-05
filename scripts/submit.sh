#!/usr/bin/env sh

CROMWELL="$1"
OPTIONS="$2"
SOURCE="$3"
INPUTS="$4"
COLLECTION="$5"

curl -s "https://${CROMWELL}/api/workflows/v1" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -F workflowOptions=@"${OPTIONS}" \
    -F workflowSource=@"${SOURCE}" \
    -F workflowInputs=@"${INPUTS}" \
    "${COLLECTION:+"-F collectionName=${COLLECTION}"}"
