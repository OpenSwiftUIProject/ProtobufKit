#!/bin/bash

SDK_NAME=$1
FRAMEWORK_NAME=$2
PATCH_FILE=$3

SDK_PATH=$(xcrun --sdk ${SDK_NAME} --show-sdk-path)

FRAMEWORK_PATH="${SDK_PATH}/System/Library/Frameworks/${FRAMEWORK_NAME}.framework"
MODULE_PATH="${FRAMEWORK_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule"

for swiftinterface_file in ${MODULE_PATH}/*.swiftinterface; do
  cat ${PATCH_FILE} >> ${swiftinterface_file}
done