#!/usr/bin/env bash
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
aws --endpoint-url=http://localhost:4566 --region "$AWS_REGION" "$@"
