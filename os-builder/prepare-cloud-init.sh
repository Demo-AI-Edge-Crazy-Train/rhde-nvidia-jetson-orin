#!/bin/bash

set -Eeuo pipefail

if [ -f ".cloud-init.env" ]; then
  . .cloud-init.env
fi

declare -a ALL_CONFIG_VARS=(CLOUD_INIT_RH_ACTIVATION_KEY CLOUD_INIT_RH_ORGANIZATION_ID CLOUD_INIT_ADMIN_USERNAME CLOUD_INIT_ADMIN_SSH_KEY CLOUD_INIT_ADMIN_PASSWORD CLOUD_INIT_S3_BUCKET_NAME)
if [ -z "${CLOUD_INIT_RH_ACTIVATION_KEY:-}" ]; then read -p "Red Hat Activation Key: " CLOUD_INIT_RH_ACTIVATION_KEY; fi
if [ -z "${CLOUD_INIT_RH_ORGANIZATION_ID:-}" ]; then read -p "Red Hat Organization Id: " CLOUD_INIT_RH_ORGANIZATION_ID; fi
if [ -z "${CLOUD_INIT_ADMIN_USERNAME:-}" ]; then read -p "Admin Username: " CLOUD_INIT_ADMIN_USERNAME; fi
if [ -z "${CLOUD_INIT_ADMIN_SSH_KEY:-}" ]; then read -p "Admin SSH key: " CLOUD_INIT_ADMIN_SSH_KEY; fi
if [ -z "${CLOUD_INIT_S3_BUCKET_NAME:-}" ]; then read -p "S3 Bucket name: " CLOUD_INIT_S3_BUCKET_NAME; fi
if [ -z "${CLOUD_INIT_ADMIN_PASSWORD:-}" ]; then
  read -s -p "Admin Password: " password
  CLOUD_INIT_ADMIN_PASSWORD="$(echo -n "$password" | mkpasswd -sm sha512crypt)"
  password=""
fi

export "${ALL_CONFIG_VARS[@]}"
declare -p | grep "declare -x CLOUD_INIT_" > .cloud-init.env

shell_format=""
for i in "${ALL_CONFIG_VARS[@]}"; do
  shell_format="$shell_format \$$i"
done

envsubst "$shell_format" < cloud-init/user-data.yaml.template > cloud-init/user-data.yaml
