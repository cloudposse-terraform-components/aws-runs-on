# -----------------------------------------------------------------------------
# TGW-compatible outputs
# These outputs match the vpc component interface so the tgw/spoke component
# can reference runs-on as a vpc_component_name.
# -----------------------------------------------------------------------------

output "vpc_id" {
  value       = local.enabled ? var.vpc_id : null
  description = "VPC ID used by RunsOn"
}

output "vpc_cidr" {
  value       = one(data.aws_vpc.this[*].cidr_block)
  description = "CIDR block of the VPC used by RunsOn"
}

output "nat_gateway_ids" {
  value       = one(data.aws_nat_gateways.ngws[*].ids)
  description = "NAT Gateway IDs in the VPC"
}

# Required by TGW component but not directly managed by RunsOn
output "nat_instance_ids" {
  value       = []
  description = "NAT Instance IDs (always empty, kept for TGW compatibility)"
}

output "private_subnet_ids" {
  value       = local.enabled ? var.private_subnet_ids : []
  description = "Private subnet IDs used by RunsOn"
}

output "public_subnet_ids" {
  value       = local.enabled ? var.public_subnet_ids : []
  description = "Public subnet IDs used by RunsOn"
}

output "security_group_id" {
  value       = local.enabled ? one(module.runs_on[*].security_group_ids[0]) : null
  description = "Primary security group ID used by RunsOn runners"
}

output "private_route_table_ids" {
  value       = []
  description = "Private route table IDs (always empty in external/BYOV mode)"
}

# -----------------------------------------------------------------------------
# RunsOn-specific outputs
# -----------------------------------------------------------------------------

output "name" {
  value       = local.enabled ? local.stack_name : null
  description = "RunsOn stack name"
}

output "id" {
  value       = module.this.id
  description = "Component ID"
}

output "outputs" {
  value = local.enabled ? {
    apprunner_service_url  = one(module.runs_on[*].apprunner_service_url)
    apprunner_service_arn  = one(module.runs_on[*].apprunner_service_arn)
    ec2_instance_role_name = one(module.runs_on[*].ec2_instance_role_name)
    ec2_instance_role_arn  = one(module.runs_on[*].ec2_instance_role_arn)
    security_group_ids     = one(module.runs_on[*].security_group_ids)
    config_bucket_name     = one(module.runs_on[*].config_bucket_name)
    cache_bucket_name      = one(module.runs_on[*].cache_bucket_name)
    dashboard_url          = one(module.runs_on[*].dashboard_url)
    sns_topic_arn          = one(module.runs_on[*].sns_topic_arn)
  } : {}
  description = "Selected outputs from the RunsOn Terraform module"
}

output "apprunner_service_url" {
  value       = one(module.runs_on[*].apprunner_service_url)
  description = "App Runner service URL (use this for GitHub App installation)"
}

output "dashboard_url" {
  value       = one(module.runs_on[*].dashboard_url)
  description = "CloudWatch dashboard URL"
}

output "ec2_instance_role_name" {
  value       = one(module.runs_on[*].ec2_instance_role_name)
  description = "EC2 instance IAM role name for runners"
}

output "ec2_instance_role_arn" {
  value       = one(module.runs_on[*].ec2_instance_role_arn)
  description = "EC2 instance IAM role ARN for runners"
}

output "security_group_ids" {
  value       = one(module.runs_on[*].security_group_ids)
  description = "Security group IDs used by RunsOn runners"
}

output "config_bucket_name" {
  value       = one(module.runs_on[*].config_bucket_name)
  description = "S3 bucket for RunsOn configuration"
}

output "cache_bucket_name" {
  value       = one(module.runs_on[*].cache_bucket_name)
  description = "S3 bucket for RunsOn cache"
}
