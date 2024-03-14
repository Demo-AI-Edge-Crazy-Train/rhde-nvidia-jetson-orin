#!/bin/bash

set -Eeuo pipefail

if [ -f ".prepare.env" ]; then
  . .prepare.env
fi

declare -a ALL_CONFIG_VARS=(KICKSTART_WIFI_SSID KICKSTART_WIFI_WPA_KEY BLUEPRINT_ADMIN_USERNAME BLUEPRINT_ADMIN_SSH_KEY BLUEPRINT_ADMIN_PASSWORD KICKSTART_OSTREE_URL KICKSTART_OSTREE_REF KICKSTART_MICROSHIFT_PULL_SECRET)
if [ -z "${KICKSTART_WIFI_SSID:-}" ]; then read -p "Wifi SSID: " KICKSTART_WIFI_SSID; fi
if [ -z "${KICKSTART_WIFI_WPA_KEY:-}" ]; then read -p "Wifi WPA Key: " KICKSTART_WIFI_WPA_KEY; fi
if [ -z "${KICKSTART_OSTREE_URL:-}" ]; then read -p "Ostree repository URL: " KICKSTART_OSTREE_URL; fi
if [ -z "${KICKSTART_OSTREE_REF:-}" ]; then read -p "Ostree reference: " KICKSTART_OSTREE_REF; fi
if [ -z "${KICKSTART_MICROSHIFT_PULL_SECRET:-}" ]; then read -p "Microshift Pull Secret: " KICKSTART_MICROSHIFT_PULL_SECRET; fi
if [ -z "${BLUEPRINT_ADMIN_USERNAME:-}" ]; then read -p "Admin Username: " BLUEPRINT_ADMIN_USERNAME; fi
if [ -z "${BLUEPRINT_ADMIN_SSH_KEY:-}" ]; then read -p "Admin SSH key: " BLUEPRINT_ADMIN_SSH_KEY; fi
if [ -z "${BLUEPRINT_ADMIN_PASSWORD:-}" ]; then
  read -s -p "Admin Password: " password
  BLUEPRINT_ADMIN_PASSWORD="$(echo -n "$password" | mkpasswd -sm sha512crypt)"
  password=""
  echo
fi

export "${ALL_CONFIG_VARS[@]}"
declare -p | grep -E "^declare -x (KICKSTART|BLUEPRINT)_" > .prepare.env

shell_format=""
for i in "${ALL_CONFIG_VARS[@]}"; do
  shell_format="$shell_format \$$i"
done

for template_file in kickstarts/*.cfg.template; do
  kickstart_file="kickstarts/$(basename "$template_file" .template)"
  echo "$template_file -> $kickstart_file"
  envsubst "$shell_format" < "$template_file" > "$kickstart_file"
done

for template_file in blueprints/*.toml.template; do
  blueprint_file="blueprints/$(basename "$template_file" .template)"
  echo "$template_file -> $blueprint_file"
  envsubst "$shell_format" < "$template_file" > "$blueprint_file"
done
