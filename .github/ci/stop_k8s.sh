#!/usr/bin/env bash

set -euo pipefail

K3D_CLUSTER_NAME="dev-cluster"
KUBECONFIG_CONTEXT="k3d-${K3D_CLUSTER_NAME}"
export NFS_DIRECTORY=/tmp/k3d_data

echo "[+] Checking k3d cluster status..."
if ! k3d cluster list | grep -q "${K3D_CLUSTER_NAME}"; then
  echo "[✓] k3d cluster already deleted."
else
  k3d cluster delete "${K3D_CLUSTER_NAME}" || (
    sleep 10 && k3d cluster delete "${K3D_CLUSTER_NAME}"
  )
  echo "[✓] k3d cluster deleted."
fi