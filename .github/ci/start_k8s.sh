#!/usr/bin/env bash

set -euo pipefail

K3D_CLUSTER_NAME="dev-cluster"
KUBECONFIG_CONTEXT="k3d-${K3D_CLUSTER_NAME}"
export NFS_DIRECTORY=/tmp/k3d_data
export NFS_SERVER=nfs-server

echo "[+] Checking k3d cluster status..."
if ! k3d cluster list | grep -q "$K3D_CLUSTER_NAME"; then
  echo "[+] Creating k3d cluster..."
  
  k3d cluster create "$K3D_CLUSTER_NAME" --config .github/ci/k3d-config.yaml
else
  echo "[✓] k3d cluster already exists."
fi

echo "[+] Setting kubectl context to ${KUBECONFIG_CONTEXT}..."
kubectl config use-context "${KUBECONFIG_CONTEXT}" || (echo ERROR && exit 1)

echo "[+] Waiting for Kubernetes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s || (echo ERROR && exit 1)

echo "[+] Running helmfile to install charts..."
helmfile apply -f .github/ci/helmfile.yaml || (echo ERROR && exit 1)