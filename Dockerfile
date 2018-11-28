##
# Base image
#
FROM google/cloud-sdk:alpine as build

ARG WOMTOOL_VERSION=36

WORKDIR /scripts

RUN apk add --no-cache \
      openjdk8-jre-base \
    && \
    wget https://github.com/broadinstitute/cromwell/releases/download/${WOMTOOL_VERSION}/womtool-${WOMTOOL_VERSION}.jar \
      -O womtool.jar

ADD /example /example
ADD /scripts .

##
# Validate example WDL and inputs
#
FROM build as validate

WORKDIR /example

RUN /scripts/validate.sh Alignment.wdl alignment.inputs.json

##
# Final image
#
FROM build as final

WORKDIR /workflow

ENTRYPOINT ["/scripts/run.sh"]
