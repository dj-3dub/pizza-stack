locals {
  name_prefix = "${var.project}"
  tags = {
    project = var.project
    env     = "local"
    owner   = "homelab"
  }
}

resource "aws_s3_bucket" "demo" {
  bucket = "${local.name_prefix}-demo-bucket"
  tags   = local.tags
}

resource "aws_dynamodb_table" "demo" {
  name           = "${local.name_prefix}-demo-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  tags = local.tags
}
