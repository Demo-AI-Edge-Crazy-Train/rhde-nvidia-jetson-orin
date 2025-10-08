#!/bin/bash

set -Eeuo pipefail

if [ ! -f /etc/default/bootstrap-microshift ]; then
  echo "Microshift manifests not configured!"
  exit 0
fi

MAX_ATTEMPTS=60
export KUBECONFIG=/var/lib/microshift/resources/kubeadmin/kubeconfig

for (( attempt=1; attempt<=MAX_ATTEMPTS; attempt++ )); do
  sleep 5
  echo "Asserting current state of the train namespace ($attempt/$MAX_ATTEMPTS)..."
  
  # Checking if microshift is running
  if ! systemctl is-active --quiet microshift; then
    echo "Microshift is not running!"
    continue
  fi

  # Checking if microshift is ready by querying nodes
  if ! oc get nodes &>/dev/null; then
    echo "Microshift is not ready!"
    continue
  fi
  if [ "$(oc get nodes -o name | wc -l)" -eq 0 ]; then
    echo "Microshift is not ready!"
    continue
  fi

  # Check if the train namespace exists
  if ! oc get namespace train &>/dev/null; then
    echo "The train namespace does not exist!"
    continue
  fi

  # Check if all pods in the train namespace are have the kubectl status Running
  deploy_states="$(oc get deploy -n train --no-headers)"
  failures=0
  while read -r deploy_name ready_count rest; do
    if [ "$ready_count" != "1/1" ]; then
      echo "Deployment $deploy_name is NOT ready: $ready_count"
      failures=1
    fi
  done <<< "$deploy_states"
  if [ "$failures" -ne 0 ]; then
    continue
  fi

  echo "The train namespace is in the expected state."
  echo "Sleeping for 10 seconds to allow services to settle..."
  sleep 10
  echo "And then start the demo!"
  oc -n train rsh deploy/capture-app curl -sSfL -X POST http://localhost:8080/capture/start
  echo
  exit 0
done

echo "The train namespace is not in the expected state after $MAX_ATTEMPTS attempts!"
exit 1
