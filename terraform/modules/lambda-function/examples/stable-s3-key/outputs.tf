output "version" {
  description = "New immutable version published from the ZIP hash"
  value       = module.lambda.version
}

output "live_alias_arn" {
  description = "Stable alias that advances to the published version"
  value       = module.lambda.qualified_arn
}
