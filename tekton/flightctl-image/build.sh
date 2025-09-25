#!/bin/bash

set -euo pipefail

TARGET_IMAGE="quay.io/nmasse-redhat/flightctl:latest"
SOURCE_IMAGE="registry.access.redhat.com/ubi9/ubi:latest"
SOURCE_REF=ubi9
TARGET_REF=flightctl

echo "Logging into quay.io..."
podman login quay.io

echo "Pulling source image $SOURCE_IMAGE for x86_64..."
podman rmi -i "$SOURCE_IMAGE"
podman pull --platform linux/amd64 "$SOURCE_IMAGE"
podman tag "$SOURCE_IMAGE" "localhost/$SOURCE_REF-x86_64"
podman rmi -i "$SOURCE_IMAGE"

echo "Pulling source image $SOURCE_IMAGE for aarch64..."
podman pull --platform linux/arm64/v8 "$SOURCE_IMAGE"
podman tag "$SOURCE_IMAGE" "localhost/$SOURCE_REF-aarch64"
podman rmi -i "$SOURCE_IMAGE"

echo "Building target image $TARGET_IMAGE for x86_64 architecture..."
buildah build --platform linux/amd64 -t localhost/$TARGET_REF-x86_64 --from "localhost/$SOURCE_REF-x86_64" .

echo "Building target image $TARGET_IMAGE for aarch64 architecture..."
buildah build --platform linux/arm64/v8 -t localhost/$TARGET_REF-aarch64 --from "localhost/$SOURCE_REF-aarch64" .

echo "Creating multi-arch manifest..."
if podman manifest exists localhost/$TARGET_REF; then
  podman manifest rm localhost/$TARGET_REF
fi
podman manifest create localhost/$TARGET_REF
podman manifest add localhost/$TARGET_REF localhost/$TARGET_REF-x86_64
podman manifest add localhost/$TARGET_REF localhost/$TARGET_REF-aarch64

echo "pushing to $TARGET_IMAGE..."
read -p "Press enter to continue "
podman manifest push --all --format v2s2 localhost/$TARGET_REF "docker://$TARGET_IMAGE"
