#!/bin/bash

set -Eeuo pipefail

if [ ! -f /etc/default/bootstrap-microshift ]; then
    echo "/etc/default/bootstrap-microshift not found, exiting"
    exit 1
fi

TEMP_DIR=$(mktemp -d /tmp/gitops.XXXXXX)
trap 'rm -rf ${TEMP_DIR}' EXIT

git clone https://github.com/Demo-AI-Edge-Crazy-Train/gitops.git ${TEMP_DIR}

declare -a HELM_VALUES_ARGS=()
while IFS= read -r line; do
    if [[ "$line" =~ ^#.*$ ]]; then
        continue
    fi
    if [[ -n "$line" ]]; then
        HELM_VALUES_ARGS+=("--set" "$line")
    fi
done < /etc/default/bootstrap-microshift

helm dependency build ${TEMP_DIR}/train
helm template train ${TEMP_DIR}/train "${HELM_VALUES_ARGS[@]}" > /etc/microshift/manifests.d/crazy-train/payload.yaml
cat > /etc/microshift/manifests.d/crazy-train/kustomization.yaml <<"EOF"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- payload.yaml
EOF
