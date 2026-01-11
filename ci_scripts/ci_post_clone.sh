#!/bin/sh

set -e

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y -t aarch64-apple-ios

PROTOC_VERSION="$(curl -sSfL https://api.github.com/repos/protocolbuffers/protobuf/releases/latest \
  | sed -n 's/ *"tag_name": "v\([^"]*\)".*/\1/p')"
PROTOC_OSX_ZIP="protoc-${PROTOC_VERSION}-osx-universal_binary.zip"
PROTOC_URL="https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_OSX_ZIP}"
curl -sSfL "${PROTOC_URL}" -o "${PROTOC_OSX_ZIP}"
mkdir -p "${HOME}/.local"
unzip -o "${PROTOC_OSX_ZIP}" -d "${HOME}/.local"
rm -f "${PROTOC_OSX_ZIP}"
