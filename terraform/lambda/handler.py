import json, os, boto3

LS_HOST = os.environ.get("LOCALSTACK_HOSTNAME", "localstack")
LS_PORT = os.environ.get("EDGE_PORT", "4566")
ENDPOINT = f"http://{LS_HOST}:{LS_PORT}"

TABLE = os.environ.get("TABLE_NAME", "")
ddb = boto3.client("dynamodb", endpoint_url=ENDPOINT)

def handler(event, context):
    method = (event.get("httpMethod") or event.get("requestContext", {}).get("http", {}).get("method") or "").upper()
    path   = event.get("path") or event.get("rawPath") or ""

    # Health: GET /slice/health
    if method == "GET" and path.endswith("/slice/health"):
        return _json(200, {"pizza": "margherita", "message": "oven is hot, slice is healthy!"})

    # Toppings: POST /toppings  -> increment counter in DDB
    if method == "POST" and path.endswith("/toppings"):
        resp = ddb.update_item(
            TableName=TABLE,
            Key={"id": {"S": "toppings"}},
            UpdateExpression="ADD toppings :one",
            ExpressionAttributeValues={":one": {"N": "1"}},
            ReturnValues="ALL_NEW",
        )
        count = resp.get("Attributes", {}).get("toppings", {}).get("N")
        return _json(200, {
            "pizza": "margherita",
            "toppings": int(count) if count is not None else None,
            "message": "your slice is hot and ready!",
        })

    return _json(404, {"error": "pizza not found", "path": path})

def _json(code, obj):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        },
        "body": json.dumps(obj),
    }
