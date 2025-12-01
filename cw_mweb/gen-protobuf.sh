#!/bin/bash

docker run --platform linux/arm64 --rm \
  -v "$PWD":/work -w /work dart:2.17 bash -c '
    apt-get update &&
    apt-get install -y protobuf-compiler &&
    dart pub global activate protoc_plugin 20.0.1 &&
    export PATH="$PATH:/root/.pub-cache/bin" &&
    protoc --dart_out=grpc:./ ./lib/mwebd.proto
  '
