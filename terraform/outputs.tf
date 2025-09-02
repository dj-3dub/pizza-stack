############################################
# Core Resources
############################################

output "s3_bucket_name" {
  value = aws_s3_bucket.demo.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.demo.name
}

############################################
# API Gateway (REST)
############################################

output "rest_api_id" {
  value = aws_api_gateway_rest_api.rest.id
}

# Root invoke URL (proxy)
output "rest_api_invoke_url_base" {
  description = "Base invoke URL for the REST API"
  value       = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.rest.id}/dev/_user_request_"
}

# Pizza routes
output "rest_api_health_url" {
  description = "Health endpoint"
  value       = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.rest.id}/dev/_user_request_/slice/health"
}

output "rest_api_toppings_url" {
  description = "Toppings counter endpoint"
  value       = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.rest.id}/dev/_user_request_/toppings"
}
