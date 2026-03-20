# ---------------------------------------------------------------------------
# Core service
# ---------------------------------------------------------------------------

output "apprunner_service_url" {
  value       = one(module.runs_on[*].apprunner_service_url)
  description = "URL of the RunsOn App Runner service (the setup/admin UI)"
}

output "apprunner_service_arn" {
  value       = one(module.runs_on[*].apprunner_service_arn)
  description = "ARN of the RunsOn App Runner service"
}

output "apprunner_service_status" {
  value       = one(module.runs_on[*].apprunner_service_status)
  description = "Operational status of the RunsOn App Runner service"
}

output "apprunner_log_group_name" {
  value       = one(module.runs_on[*].apprunner_log_group_name)
  description = "CloudWatch log group name for the App Runner service"
}

output "stack_name" {
  value       = local.stack_name
  description = "RunsOn stack name used for resource naming"
}

# ---------------------------------------------------------------------------
# IAM / compute
# ---------------------------------------------------------------------------

output "ec2_instance_role_name" {
  value       = one(module.runs_on[*].ec2_instance_role_name)
  description = "Name of the IAM role attached to runner EC2 instances"
}

output "ec2_instance_role_arn" {
  value       = one(module.runs_on[*].ec2_instance_role_arn)
  description = "ARN of the IAM role attached to runner EC2 instances"
}

output "ec2_instance_profile_arn" {
  value       = one(module.runs_on[*].ec2_instance_profile_arn)
  description = "ARN of the EC2 instance profile"
}

output "ec2_instance_log_group_name" {
  value       = one(module.runs_on[*].ec2_instance_log_group_name)
  description = "CloudWatch log group name for EC2 runner instances"
}

# ---------------------------------------------------------------------------
# Security groups
# ---------------------------------------------------------------------------

output "security_group_id" {
  value       = try(one(module.runs_on[*].security_group_ids)[0], null)
  description = "Primary security group ID used by runner instances (first in the list)"
}

output "security_group_ids" {
  value       = one(module.runs_on[*].security_group_ids)
  description = "Security group IDs used by runner instances (created or provided)"
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

output "config_bucket_name" {
  value       = one(module.runs_on[*].config_bucket_name)
  description = "Name of the S3 configuration bucket"
}

output "cache_bucket_name" {
  value       = one(module.runs_on[*].cache_bucket_name)
  description = "Name of the S3 cache bucket"
}

output "logging_bucket_name" {
  value       = one(module.runs_on[*].logging_bucket_name)
  description = "Name of the S3 logging bucket"
}

# ---------------------------------------------------------------------------
# SNS / alerting
# ---------------------------------------------------------------------------

output "sns_topic_arn" {
  value       = one(module.runs_on[*].sns_topic_arn)
  description = "ARN of the SNS alerts topic"
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------

output "dashboard_url" {
  value       = one(module.runs_on[*].dashboard_url)
  description = "URL to the CloudWatch Dashboard (when enable_dashboard = true)"
}

# ---------------------------------------------------------------------------
# VPC / networking — kept for backward compatibility with TGW spoke integration
# ---------------------------------------------------------------------------

output "vpc_id" {
  value       = var.vpc_id
  description = "ID of the VPC where RunsOn is deployed"
}

output "vpc_cidr" {
  value       = local.vpc_cidr_block
  description = "CIDR block of the VPC where RunsOn is deployed"
}

output "nat_gateway_ids" {
  value       = one(data.aws_nat_gateways.ngws[*].ids)
  description = "NAT Gateway IDs in the VPC"
}

# Required by TGW component but not applicable here
output "nat_instance_ids" {
  value       = []
  description = "NAT Instance IDs (always empty; RunsOn uses NAT Gateways)"
}

output "private_subnet_ids" {
  value       = local.all_private_subnet_ids
  description = "Private subnet IDs discovered from the VPC"
}

output "public_subnet_ids" {
  value       = local.all_public_subnet_ids
  description = "Public subnet IDs discovered from the VPC"
}

output "private_route_table_ids" {
  value       = local.private_route_table_ids
  description = "Route table IDs associated with the private subnets (used by TGW spoke component)"
}
