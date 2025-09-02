terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.region
  access_key                  = "test"
  secret_key                  = "test"

  # For S3 with LocalStack
  s3_use_path_style           = true

  # Skip real-account checks
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  # Make sure every used service points to LocalStack
  endpoints {
    # API Gateway (REST) and HTTP API (v2) need explicit keys
    apigateway   = "http://localhost:4566"
    apigatewayv2 = "http://localhost:4566"

    cloudwatch = "http://localhost:4566"
    dynamodb   = "http://localhost:4566"
    iam        = "http://localhost:4566"
    lambda     = "http://localhost:4566"
    logs       = "http://localhost:4566"
    s3         = "http://localhost:4566"
    sts        = "http://localhost:4566"
  }
}
