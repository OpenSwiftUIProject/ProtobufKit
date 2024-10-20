#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd $PROJECT_ROOT

swift package --allow-writing-to-package-directory benchmark thresholds update --target ProtobufKitBenchmarks --path ./Thresholds/ProtobufKit/1.0
swift package --allow-writing-to-package-directory benchmark thresholds update --target SwiftProtobufBenchmarks --path ./Thresholds/SwiftProtobuf/1.28