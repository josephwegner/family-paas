output "lambda_deployments_bucket" {
  description = "S3 bucket name for Lambda deployment packages"
  value       = aws_s3_bucket.lambda_deployments.id
}

output "lambda_deployments_bucket_arn" {
  description = "S3 bucket ARN for Lambda deployment packages"
  value       = aws_s3_bucket.lambda_deployments.arn
}

output "shared_media_bucket" {
  description = "S3 bucket name for shared media assets"
  value       = aws_s3_bucket.shared_media.id
}

output "shared_media_bucket_arn" {
  description = "S3 bucket ARN for shared media assets"
  value       = aws_s3_bucket.shared_media.arn
}

output "shared_dynamodb_table" {
  description = "DynamoDB table name for shared app data"
  value       = aws_dynamodb_table.shared_data.name
}

output "shared_dynamodb_table_arn" {
  description = "DynamoDB table ARN for shared app data"
  value       = aws_dynamodb_table.shared_data.arn
}

output "account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.family.id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.family.arn
}

output "cognito_user_pool_issuer" {
  description = "Cognito User Pool issuer URL for JWT validation"
  value       = "https://cognito-idp.us-east-1.amazonaws.com/${aws_cognito_user_pool.family.id}"
}
