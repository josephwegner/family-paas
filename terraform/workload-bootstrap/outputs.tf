output "lambda_deployments_bucket" {
  value = aws_s3_bucket.lambda_deployments.id
}
