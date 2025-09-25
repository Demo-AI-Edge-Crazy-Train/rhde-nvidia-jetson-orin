#!/bin/bash

set -Eeuo pipefail

while ! dmesg -t | grep -G "hci[0-9]: RTL: fw version " &>/dev/null; do
  echo "Firmware of rtk_btusb not loaded properly!"
  
  for path in /sys/bus/usb/devices/[0-9]-[0-9]/; do
    if [ ! -e "$path/idVendor" -o ! -e "$path/idProduct" ]; then
      continue
    fi
    
    vendor_id="$(cat $path/idVendor)"
    product_id="$(cat $path/idProduct)"
    if [ "$vendor_id:$product_id" == "13d3:3549" ]; then
      echo "Rebooting device $vendor_id:$product_id..."
      echo -n 0 > "$path/authorized"
      sleep 2
      echo -n 1 > "$path/authorized"
      sleep 10
    fi
  done
done
