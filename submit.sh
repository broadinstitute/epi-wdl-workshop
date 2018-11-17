#!/usr/bin/env sh

OPTIONS="$1"
SOURCE="$2"
INPUTS="$3"


CROMWELL="cromwell.caas-prod.broadinstitute.org"

curl "https://${CROMWELL}/api/workflows/v1" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -F workflowOptions=@"${OPTIONS}" \
    -F workflowSource=@"${SOURCE}" \
    -F workflowInputs=@"${INPUTS}"
