#!/usr/bin/env bash
# Robust pizza lab smoke test for LocalStack + Terraform
# - No awk/regex parsing
# - No 'set -e' so we can handle failures gracefully
# - Clear pass/fail lines for each check

set -u

fail() { echo "fail: $*" ; exit 1; }
ok()   { echo "ok: $*" ; }

aws_local() {
  AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}" \
  AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}" \
  AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}" \
  aws --endpoint-url=http://localhost:4566 --region "${AWS_DEFAULT_REGION}" "$@"
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

echo "[*] Smoke test"

# --- Basic tool checks ---
need aws
need curl
need terraform

# --- Discover from Terraform outputs/state (no awk needed) ---
tf_out_raw() { terraform -chdir=terraform output -raw "$1" 2>/dev/null || true; }

BUCKET="$(tf_out_raw s3_bucket_name)"
TABLE="$(tf_out_raw dynamodb_table_name)"
REST_ID="$(tf_out_raw rest_api_id)"

# Fallback to state if outputs missing
if [[ -z "${BUCKET}" ]]; then
  BUCKET="$(terraform -chdir=terraform state show aws_s3_bucket.demo 2>/dev/null \
            | sed -n 's/^ *bucket *= *"\(.*\)"/\1/p' | head -n1 || true)"
fi
if [[ -z "${TABLE}" ]]; then
  TABLE="$(terraform -chdir=terraform state show aws_dynamodb_table.demo 2>/dev/null \
           | sed -n 's/^ *name *= *"\(.*\)"/\1/p' | head -n1 || true)"
fi
if [[ -z "${REST_ID}" ]]; then
  REST_ID="$(terraform -chdir=terraform state show aws_api_gateway_rest_api.rest 2>/dev/null \
             | sed -n 's/^ *id *= *"\(.*\)"/\1/p' | head -n1 || true)"
fi

# Infer project from bucket name
PROJECT=""
if [[ -n "${BUCKET}" && "${BUCKET}" == *"-demo-bucket" ]]; then
  PROJECT="${BUCKET%-demo-bucket}"
fi

[[ -n "${PROJECT}" && -n "${BUCKET}" && -n "${TABLE}" ]] || \
  fail "could not detect PROJECT/BUCKET/TABLE from terraform (run 'make tf-apply' first). \
PROJECT='${PROJECT:-}' BUCKET='${BUCKET:-}' TABLE='${TABLE:-}'"

echo "    project: ${PROJECT}"
echo "    bucket : ${BUCKET}"
echo "    table  : ${TABLE}"

# --- LocalStack health (non-fatal) ---
if curl -sS http://localhost:4566/_localstack/health >/dev/null 2>&1; then
  ok "LocalStack edge reachable on :4566"
else
  echo "warn: LocalStack health endpoint not reachable (continuing)"
fi

# --- S3 check ---
if aws_local s3 ls "s3://${BUCKET}" >/dev/null 2>&1; then
  ok "S3 bucket exists"
else
  fail "S3 bucket '${BUCKET}' missing"
fi

# --- DynamoDB check ---
TABLES="$(aws_local dynamodb list-tables --output text --query 'TableNames' 2>/dev/null || true)"
if echo "${TABLES}" | grep -qw "${TABLE}"; then
  ok "DynamoDB table exists"
else
  fail "DynamoDB table '${TABLE}' missing"
fi

# --- Pizza API checks ---
[[ -n "${REST_ID}" ]] || fail "REST API id not found from terraform (ensure API was applied)."
BASE="http://localhost:4566/restapis/${REST_ID}/dev/_user_request_"

HURL="${BASE}/slice/health"
TURL="${BASE}/toppings"

code=$(curl -s -o /dev/null -w "%{http_code}" "${HURL}")
[[ "${code}" == "200" ]] && ok "GET /slice/health -> 200" || fail "/slice/health -> ${code}"

code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${TURL}")
[[ "${code}" == "200" ]] && ok "POST /toppings -> 200" || fail "/toppings -> ${code}"

echo "✓ Smoke test passed"
exit 0
