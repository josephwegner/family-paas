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
