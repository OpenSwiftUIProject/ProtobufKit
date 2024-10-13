#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd $PROJECT_ROOT

swift package benchmark thresholds check --target ProtobufKitBenchmarks --path ./Thresholds/ProtobufKit/1.0
swift package benchmark thresholds check --target SwiftProtobufBenchmarks --path ./Thresholds/SwiftProtobuf/1.28