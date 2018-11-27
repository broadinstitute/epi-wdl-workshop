FROM google/cloud-sdk:alpine

ENV CLOUDSDK_CONFIG=/cromwell
WORKDIR /workflow

ADD /example /example
ADD /scripts /scripts

ENTRYPOINT ["/scripts/run.sh"]
