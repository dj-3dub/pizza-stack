#!/usr/bin/env python3
from __future__ import annotations
import argparse, os, re, subprocess, sys
from typing import Optional, Tuple
import requests, boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

GREEN, RED = "✅", "❌"

def sh(cmd: list[str]) -> Tuple[int,str,str]:
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out, err = p.communicate()
    return p.returncode, out.strip(), err.strip()

def tf_output_raw(name: str, tf_dir: str) -> Optional[str]:
    rc, out, _ = sh(["terraform", "-chdir="+tf_dir, "output", "-raw", name])
    return out if rc == 0 and out else None

def tf_state_attr(addr: str, attr: str, tf_dir: str) -> Optional[str]:
    rc, out, _ = sh(["terraform", "-chdir="+tf_dir, "state", "show", addr])
    if rc != 0: return None
    m = re.search(rf"^\s*{re.escape(attr)}\s*=\s*\"([^\"]+)\"", out, flags=re.MULTILINE)
    return m.group(1) if m else None

def detect_stack_names(tf_dir: str):
    bucket = tf_output_raw("s3_bucket_name", tf_dir) or ""
    table  = tf_output_raw("dynamodb_table_name", tf_dir) or ""
    rest   = tf_output_raw("rest_api_id", tf_dir) or ""
    if not bucket: bucket = tf_state_attr("aws_s3_bucket.demo", "bucket", tf_dir) or ""
    if not table : table  = tf_state_attr("aws_dynamodb_table.demo", "name", tf_dir) or ""
    if not rest  : rest   = tf_state_attr("aws_api_gateway_rest_api.rest", "id", tf_dir) or ""
    if not all([bucket, table, rest]): raise RuntimeError("Could not detect names from Terraform. Run 'make tf-apply' first.")
    project = bucket[:-12] if bucket.endswith("-demo-bucket") else "unknown"
    return project, bucket, table, rest

def make_clients(endpoint: str, region: str):
    cfg = Config(region_name=region, retries={"max_attempts":3,"mode":"standard"})
    session = boto3.Session(
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID","test"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY","test"),
        region_name=region,
    )
    return session.client("s3", endpoint_url=endpoint, config=cfg), session.client("dynamodb", endpoint_url=endpoint, config=cfg)

def check_localstack(base: str, timeout: float):
    try:
        r = requests.get(f"{base}/_localstack/health", timeout=timeout)
        return (200 <= r.status_code < 500, f"LocalStack edge reachable ({r.status_code})")
    except Exception as e:
        return (False, f"LocalStack not reachable: {e}")

def check_s3(s3, bucket: str):
    try:
        s3.head_bucket(Bucket=bucket); return True, f"S3 bucket '{bucket}' exists"
    except (BotoCoreError, ClientError) as e:
        return False, f"S3 bucket check failed: {e}"

def check_ddb(ddb, table: str):
    try:
        ddb.describe_table(TableName=table); return True, f"DynamoDB table '{table}' exists"
    except (BotoCoreError, ClientError) as e:
        return False, f"DynamoDB table check failed: {e}"

def check_api(exec_base: str, timeout: float):
    ok_all, results = True, []
    try:
        r = requests.get(f"{exec_base}/slice/health", timeout=timeout)
        results.append((r.status_code == 200, f"GET /slice/health -> {r.status_code}"))
        if r.status_code != 200: ok_all = False
    except Exception as e:
        results.append((False, f"GET /slice/health error: {e}")); ok_all = False
    try:
        r = requests.post(f"{exec_base}/toppings", timeout=timeout)
        results.append((r.status_code == 200, f"POST /toppings -> {r.status_code}"))
        if r.status_code != 200: ok_all = False
    except Exception as e:
        results.append((False, f"POST /toppings error: {e}")); ok_all = False
    return ok_all, results

def main():
    ap = argparse.ArgumentParser(description="Pizza stack sanity check (LocalStack + Terraform)")
    ap.add_argument("--tf-dir", default="terraform")
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", default="4566")
    ap.add_argument("--region", default=os.environ.get("AWS_DEFAULT_REGION","us-east-1"))
    ap.add_argument("--timeout", type=float, default=5.0)
    args = ap.parse_args()

    base = f"http://{args.host}:{args.port}"
    try:
        project, bucket, table, rest = detect_stack_names(args.tf_dir)
    except Exception as e:
        print(f"{RED} fail: {e}"); return 2

    print("[*] Pizza stack sanity check")
    print(f"    project : {project}")
    print(f"    bucket  : {bucket}")
    print(f"    table   : {table}")
    print(f"    rest_id : {rest}")

    ok_h, msg_h = check_localstack(base, args.timeout); print((GREEN if ok_h else RED), msg_h)
    s3, ddb = make_clients(base, args.region)
    ok_s3, msg_s3 = check_s3(s3, bucket); print((GREEN if ok_s3 else RED), msg_s3)
    ok_ddb, msg_ddb = check_ddb(ddb, table); print((GREEN if ok_ddb else RED), msg_ddb)

    exec_base = f"{base}/restapis/{rest}/dev/_user_request_"
    ok_api, api_msgs = check_api(exec_base, args.timeout)
    for ok, msg in api_msgs: print((GREEN if ok else RED), msg)

    if ok_h and ok_s3 and ok_ddb and ok_api:
        print(f"{GREEN} All checks passed"); return 0
    print(f"{RED} One or more checks failed"); return 1

if __name__ == "__main__":
    sys.exit(main())
PY
