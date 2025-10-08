#!/bin/bash

set -Eeuo pipefail

MAX_ATTEMPTS=5
done=0
for (( count=0; count<MAX_ATTEMPTS; count++ )); do
  if [ "$count" -eq 0 ] || ! dmesg -t | grep -G "hci[0-9]: RTL: fw version " &>/dev/null; then
    echo "Reloading firmware of rtk_btusb (attempt $count)..."
  
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
  else
    echo "Firmware of rtk_btusb loaded properly after $count attempts."
    done=1
    break
  fi
done
if [[ "$done" != 1 ]]; then
  echo "Firmware of rtk_btusb not loaded properly after $count attempts!"
fi

done=0
for (( count=0; count<$MAX_ATTEMPTS; count++ )); do
  if ! bluetoothctl power on; then
    echo "Failed to power on bluetooth controller. Retrying in 5 seconds..."
    sleep 5
    continue
  fi

  if ! bluetoothctl pairable on; then
    echo "Failed to set bluetooth controller to pairable. Retrying in 5 seconds..."
    sleep 5
    continue
  fi

  if ! bluetoothctl discoverable on; then
    echo "Failed to set bluetooth controller to pairable. Retrying in 5 seconds..."
    sleep 5
    continue
  fi

  echo "Bluetooth controller is powered on, pairable, and discoverable after $count attempts."
  done=1
  break
done
if [[ "$done" != 1 ]]; then
  echo "Bluetooth controller could not be initialized after $count attempts!"
fi

exit 0