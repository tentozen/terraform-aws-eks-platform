output "region" {
  description = "AWS region."
  value       = data.aws_region.current.region
}

output "account_id" {
  description = "AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}
