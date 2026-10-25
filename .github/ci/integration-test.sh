#!/usr/bin/env bash
#
# Integration test for the Garage chart: deploys the chart to a throwaway k3d
# cluster and checks the cluster end to end, including the Garage v2.5.0 features
# this chart exposes (`public_endpoint`, JSON logs, lifecycle ACL).
#
# Requirements: k3d, kubectl, helm, aws (CLI v2), jq, python3.
# Local usage: ./.github/ci/integration-test.sh
# Keep the cluster for debugging: KEEP_CLUSTER=true ./.github/ci/integration-test.sh

set -euo pipefail

CLUSTER_NAME="${K3D_CLUSTER_NAME:-garage-it}"
RELEASE="${RELEASE:-it}"
NAMESPACE="${NAMESPACE:-garage-it}"
CHART="${CHART:-garage/}"
VALUES_FILE="${VALUES_FILE:-.github/ci/integration-values.yaml}"
S3_PORT=3900
ADMIN_PORT=3903
POD="${RELEASE}-garage-0"

PF_PIDS=()

log() { printf '\n[integration] %s\n' "$*"; }
fail() { printf '\n[integration] FAIL: %s\n' "$*" >&2; exit 1; }

cleanup() {
  local status=$?
  for pid in "${PF_PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  if [[ "${KEEP_CLUSTER:-false}" != "true" ]]; then
    log "Deleting k3d cluster ${CLUSTER_NAME}"
    k3d cluster delete "$CLUSTER_NAME" >/dev/null 2>&1 || true
  fi
  exit "$status"
}
trap cleanup EXIT

# --- cluster and release ------------------------------------------------------

if k3d cluster list -o json | jq -e --arg c "$CLUSTER_NAME" '.[] | select(.name == $c)' >/dev/null; then
  log "Reusing k3d cluster ${CLUSTER_NAME}"
else
  log "Creating k3d cluster ${CLUSTER_NAME}"
  k3d cluster create "$CLUSTER_NAME" --wait --timeout 180s
fi
kubectl config use-context "k3d-${CLUSTER_NAME}" >/dev/null

log "Installing chart ${CHART} as release ${RELEASE}"
helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" --create-namespace \
  --values "$VALUES_FILE" \
  --wait --timeout 15m

log "Waiting for Garage pods"
kubectl wait --namespace "$NAMESPACE" --for=condition=Ready \
  "pod" --selector "app.kubernetes.io/instance=${RELEASE}" --timeout=5m

# --- helpers ------------------------------------------------------------------

port_forward() {
  local service=$1 local_port=$2 remote_port=$3
  kubectl port-forward --namespace "$NAMESPACE" "svc/${service}" \
    "${local_port}:${remote_port}" >/tmp/pf-"${local_port}".log 2>&1 &
  PF_PIDS+=("$!")
}

wait_for_http() {
  local url=$1 port=$2
  for _ in $(seq 1 60); do
    # Any HTTP status proves the port-forward is up; 403/404 are expected on /
    if [[ $(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null) != "000" ]]; then
      return 0
    fi
    sleep 1
  done
  cat /tmp/pf-"${port}".log >&2 || true
  fail "port-forward on ${port} did not become ready"
}

# Read the values actually deployed so the assertions never duplicate them.
VALUES_JSON=$(helm get values --namespace "$NAMESPACE" "$RELEASE" -o json)
ADMIN_TOKEN=$(jq -er '.garage.secret.adminToken' <<<"$VALUES_JSON")
PUBLIC_ENDPOINT=$(jq -er '.garage.s3.api.publicEndpoint' <<<"$VALUES_JSON")
BUCKET=$(jq -er '.clusterConfig.buckets[0].name' <<<"$VALUES_JSON")
OWNER_KEY_ID=$(jq -er '.clusterConfig.keys["integration-key"].keyId' <<<"$VALUES_JSON")
OWNER_SECRET=$(jq -er '.clusterConfig.keys["integration-key"].secretKey' <<<"$VALUES_JSON")
RO_KEY_ID=$(jq -er '.clusterConfig.keys["integration-readonly-key"].keyId' <<<"$VALUES_JSON")
RO_SECRET=$(jq -er '.clusterConfig.keys["integration-readonly-key"].secretKey' <<<"$VALUES_JSON")

# --- image and admin API ------------------------------------------------------

log "Checking the deployed Garage version"
IMAGE=$(kubectl get statefulset --namespace "$NAMESPACE" "${RELEASE}-garage" \
  -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMAGE" == *":v2.5.0" ]] || fail "expected image tag v2.5.0, got ${IMAGE}"

port_forward "${RELEASE}-garage" "$ADMIN_PORT" "$ADMIN_PORT"
wait_for_http "http://127.0.0.1:${ADMIN_PORT}/health" "$ADMIN_PORT"

log "Checking the admin API connection parameters"
curl -fsS -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  "http://127.0.0.1:${ADMIN_PORT}/v2/GetNodeInfo?node=self" -o /tmp/node-info.json \
  || fail "GetNodeInfo request failed"

PUBLIC_ENDPOINT="$PUBLIC_ENDPOINT" python3 - <<'PY'
import json, os, sys
info = json.load(open('/tmp/node-info.json'))
# `?node=self` still goes through the multi-node envelope in v2.5.0
if 'success' in info and 'error' in info:
    entries = list(info['success'].values())
    if len(entries) != 1:
        sys.exit(f"expected one node in GetNodeInfo, got {len(entries)}: {info}")
    info = entries[0]
version = info.get('garageVersion', '')
if not version.lstrip('v').startswith('2.5.'):
    sys.exit(f"unexpected garageVersion {version!r}")
params = info.get('connectionParameters')
if not params:
    sys.exit("GetNodeInfo returned no connectionParameters")
expected = os.environ['PUBLIC_ENDPOINT'].rstrip('/')
# Garage normalises the URI and reports a trailing slash
if params.get('s3Endpoint', '').rstrip('/') != expected:
    sys.exit(f"s3Endpoint is {params.get('s3Endpoint')!r}, expected {expected!r}")
if params.get('s3UsePathStyle') is not False:
    sys.exit(f"s3UsePathStyle is {params.get('s3UsePathStyle')!r}, expected False")
print("connectionParameters:", params)
PY

# --- JSON logs ----------------------------------------------------------------

log "Checking JSON log output"
# Capture first: piping kubectl into `head` trips `set -o pipefail` on SIGPIPE.
LOGS=$(kubectl logs --namespace "$NAMESPACE" "$POD" --tail=50)
FIRST_LOG_LINE=${LOGS%%$'\n'*}
[[ -n "$FIRST_LOG_LINE" ]] || fail "no log lines from ${POD}"
printf '%s' "$FIRST_LOG_LINE" | python3 -c '
import json, sys
record = json.load(sys.stdin)
assert isinstance(record, dict), "log line is not a JSON object"
assert "level" in record, "log line has no level field"
' || fail "log line is not JSON: ${FIRST_LOG_LINE}"

# --- S3 API -------------------------------------------------------------------

port_forward "${RELEASE}-garage" "$S3_PORT" "$S3_PORT"
wait_for_http "http://127.0.0.1:${S3_PORT}/" "$S3_PORT"

S3="aws --endpoint-url http://127.0.0.1:${S3_PORT}"
export AWS_DEFAULT_REGION=garage
export AWS_EC2_METADATA_DISABLED=true

owner_env() {
  export AWS_ACCESS_KEY_ID="$OWNER_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$OWNER_SECRET"
}
readonly_env() {
  export AWS_ACCESS_KEY_ID="$RO_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$RO_SECRET"
}

log "Waiting for the configured bucket"
owner_env
for _ in $(seq 1 30); do
  $S3 s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1 && break
  sleep 2
done
$S3 s3api head-bucket --bucket "$BUCKET" >/dev/null \
  || fail "bucket ${BUCKET} was not created by the configuration job"

log "Round-tripping an object through the S3 API"
owner_env
printf 'garage-helm integration test\n' >/tmp/payload.txt
$S3 s3api put-object --bucket "$BUCKET" --key integration/payload.txt \
  --body /tmp/payload.txt >/dev/null || fail "PutObject failed"
$S3 s3api get-object --bucket "$BUCKET" --key integration/payload.txt \
  /tmp/payload.out >/dev/null || fail "GetObject failed"
cmp -s /tmp/payload.txt /tmp/payload.out || fail "GetObject returned different content"

log "Checking lifecycle ACL (v2.5.0: owner only)"
cat >/tmp/lifecycle.json <<'JSON'
{"Rules":[{"Filter":{"Prefix":""},"Status":"Enabled","Expiration":{"Days":1}}]}
JSON
owner_env
$S3 s3api put-bucket-lifecycle-configuration --bucket "$BUCKET" \
  --lifecycle-configuration file:///tmp/lifecycle.json \
  || fail "owner key could not set the lifecycle configuration"

readonly_env
if $S3 s3api get-bucket-lifecycle-configuration --bucket "$BUCKET" >/dev/null 2>/tmp/lifecycle.err; then
  fail "non-owner key was allowed to read the lifecycle configuration"
fi
grep -q "AccessDenied" /tmp/lifecycle.err \
  || fail "non-owner key got an unexpected error: $(cat /tmp/lifecycle.err)"

log "All integration checks passed"
