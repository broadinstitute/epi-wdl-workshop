#!/usr/bin/env sh

SOURCE="$1"
INPUTS="$2"

SCRIPTS_DIR=$(dirname "$0")

java -jar "${SCRIPTS_DIR}/womtool.jar" \
  validate "${SOURCE}" -i "${INPUTS}"
