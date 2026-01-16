#!/bin/bash

set -Eeuo pipefail

SOURCE="rhel-9.4-aarch64-boot.iso"
DEST="install-rhde-aarch64-online.iso"
KS="jetson.ks"

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root!"
  exit 1
fi

if [ ! -f "${SOURCE}" ]; then
  echo "Source ISO ${SOURCE} not found!"
  exit 1
fi

if [ ! -f "${KS}" ]; then
  echo "Kickstart ${KS} not found!"
  exit 1
fi

if [[ "$(arch)" != "aarch64" ]]; then
  echo "This script must be run on an aarch64 system!"
  exit 1
fi

declare -a MKKSISO_OPTS=()
MKKSISO_OPTS+=( -R 'set timeout=60' 'set timeout=5' )
MKKSISO_OPTS+=( -R 'set default="1"' 'set default="0"' )
MKKSISO_OPTS+=( -c "console=tty0" )
MKKSISO_OPTS+=( --ks "${KS}" )

rm -f "${DEST}"
mkksiso "${MKKSISO_OPTS[@]}" "${SOURCE}" "${DEST}"
