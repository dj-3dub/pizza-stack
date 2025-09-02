############################################
# Locals & Tags
############################################
locals {
  name_prefix = "${var.project}"
  tags = {
    project = var.project
    env     = "local"
    owner   = "homelab"
  }
}

############################################
# Core Resources: S3 + DynamoDB
############################################

resource "aws_s3_bucket" "demo" {
  bucket = "${local.name_prefix}-demo-bucket"
  tags   = local.tags
}

resource "aws_dynamodb_table" "demo" {
  name         = "${local.name_prefix}-demo-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.tags
}

############################################
# S3 Versioning + Lifecycle
############################################

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "demo" {
  bucket     = aws_s3_bucket.demo.id
  depends_on = [aws_s3_bucket_versioning.demo]

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

############################################
# Lambda IAM (execution role + inline policy)
############################################

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${local.name_prefix}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_inline" {
  statement {
    sid     = "Logs"
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "DDB"
    effect  = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
      "dynamodb:DescribeTable",
    ]
    resources = [aws_dynamodb_table.demo.arn]
  }
}

resource "aws_iam_role_policy" "lambda_exec_inline" {
  name   = "${local.name_prefix}-lambda-inline"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_inline.json
}

############################################
# Lambda Function
############################################

resource "aws_lambda_function" "hello" {
  function_name    = "${local.name_prefix}-hello"
  filename         = "${path.module}/lambda/hello.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/hello.zip")
  handler          = "handler.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.demo.name
    }
  }

  tags = local.tags
}

############################################
# API Gateway (REST v1) – Root & Proxy
############################################

resource "aws_api_gateway_rest_api" "rest" {
  name = "${local.name_prefix}-restapi"
  tags = local.tags
}

# Proxy /{proxy+}
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "any_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_proxy" { # <— declared
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.any_proxy.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello.arn}/invocations"
}

# Root /
resource "aws_api_gateway_method" "any_root" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_rest_api.rest.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" { # <— declared
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_rest_api.rest.root_resource_id
  http_method             = aws_api_gateway_method.any_root.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello.arn}/invocations"
}

############################################
# Pizza Routes
############################################

# /slice/health  (GET -> Lambda proxy)
resource "aws_api_gateway_resource" "slice" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "slice"
}

resource "aws_api_gateway_resource" "slice_health" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_resource.slice.id
  path_part   = "health"
}

resource "aws_api_gateway_method" "get_slice_health" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.slice_health.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_slice_health" { # <— declared
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_resource.slice_health.id
  http_method             = aws_api_gateway_method.get_slice_health.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello.arn}/invocations"
}

# /toppings  (POST -> Lambda proxy)
resource "aws_api_gateway_resource" "toppings" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "toppings"
}

resource "aws_api_gateway_method" "post_toppings" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.toppings.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_toppings" { # <— declared
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_resource.toppings.id
  http_method             = aws_api_gateway_method.post_toppings.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello.arn}/invocations"
}

############################################
# Deployment & Stage (unified)
############################################

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.rest.id

  triggers = {
    redeploy_hash = sha1(jsonencode({
      any_proxy         = aws_api_gateway_integration.lambda_proxy.id
      any_root          = aws_api_gateway_integration.lambda_root.id
      slice_health      = aws_api_gateway_integration.lambda_slice_health.id
      toppings_proxy    = aws_api_gateway_integration.lambda_toppings.id
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  deployment_id = aws_api_gateway_deployment.deploy.id
  stage_name    = "dev"
  tags          = local.tags
}

############################################
# Permissions
############################################

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest.execution_arn}/*/*"
}
