#!/bin/bash -e

# NOTE: This script expects to be called by the terraform module it belongs to.

: "${OUTPUT_DIR:?must be set}"
: "${OUTPUT_FILENAME:?must be set}"
: "${RAW_CONFIG:?must be set}"

if [ ! -e "${OUTPUT_DIR}" ]; then
    mkdir -p "${OUTPUT_DIR}"
fi

echo "${RAW_CONFIG}" > "${OUTPUT_DIR}/${OUTPUT_FILENAME}"
