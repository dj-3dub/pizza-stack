#!/usr/bin/env bash
AWS_REGION="${AWS_REGION:-us-east-1}"
aws --endpoint-url=http://localhost:4566 --region "$AWS_REGION" "$@"
