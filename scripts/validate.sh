#!/usr/bin/env sh

SOURCE="$1"
INPUTS="$2"

java -jar "$(dirname "$0")/womtool.jar" \
  validate "${SOURCE}" -i "${INPUTS}"
