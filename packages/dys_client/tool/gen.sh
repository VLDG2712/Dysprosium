#!/usr/bin/env bash
# Regenerate Dart stubs from ../../proto. Needs protoc + `dart pub global activate protoc_plugin`.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf lib/src/gen && mkdir -p lib/src/gen
protoc --dart_out=grpc:lib/src/gen -I ../../proto ../../proto/dys/v1/dys.proto
