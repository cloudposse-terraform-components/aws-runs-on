locals {
  enabled = module.this.enabled

<<<<<<< Updated upstream
  # Extract version from template URL (e.g., "template-v2.11.0.yaml" -> "2.11.0")
  # The parameter name changed from ExternalVpcSubnetIds to ExternalVpcPublicSubnetIds in v2.8.0
  # The ExternalVpcPrivateSubnetIds parameter was added in v2.8.0
  version_match          = regex("template-v([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.yaml", var.template_url)
  template_version_major = tonumber(local.version_match[0])
  template_version_minor = tonumber(local.version_match[1])
  use_new_subnet_param   = local.template_version_major > 2 || (local.template_version_major == 2 && local.template_version_minor >= 8)
  subnet_ids_param_name  = local.use_new_subnet_param ? "ExternalVpcPublicSubnetIds" : "ExternalVpcSubnetIds"

  # ExternalVpcPrivateSubnetIds is only supported in v2.8.0+
  private_subnet_ids_supported = local.use_new_subnet_param

  external_vpc_id             = var.vpc_id != null ? { "ExternalVpcId" = var.vpc_id } : {}
  networking_stack            = var.networking_stack != null ? { "NetworkingStack" = var.networking_stack } : {}
  subnet_ids                  = var.subnet_ids != null ? { (local.subnet_ids_param_name) = join(",", var.subnet_ids) } : {}
  external_private_subnet_ids = var.private_subnet_ids != null && local.private_subnet_ids_supported ? { "ExternalVpcPrivateSubnetIds" = join(",", var.private_subnet_ids) } : {}
  // If var.security_group_id is provided, we use it. Otherwise, if we are using the external networking stack, we create one.
  external_security_group_id = var.security_group_id != null ? { "ExternalVpcSecurityGroupId" = var.security_group_id } : {}
  // If var.security_group_id is not provided and we are using the external networking stack, we create one.
  created_security_group_id = var.security_group_id == null && var.networking_stack == "external" ? { "ExternalVpcSecurityGroupId" = module.security_group.id } : {}

  parameters = merge({
    "EC2InstanceCustomPolicy" = module.iam_policy.policy_arn
    }, var.parameters
    , local.networking_stack
    , local.external_vpc_id
    , local.subnet_ids
    , local.external_private_subnet_ids
    , local.external_security_group_id
    , local.created_security_group_id
  )

}

module "iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.2"

  context = module.this.context
  enabled = module.this.enabled

  iam_policy_enabled = true
  iam_policy = [
    {
      version   = "2012-10-17"
      policy_id = "example"
      statements = [
        {
          sid    = "AllowECRActions"
          effect = "Allow"
          actions = [
            "ecr:UploadLayerPart",
            "ecr:UntagResource",
            "ecr:TagResource",
            "ecr:StartLifecyclePolicyPreview",
            "ecr:StartImageScan",
            "ecr:PutLifecyclePolicy",
            "ecr:PutImageTagMutability",
            "ecr:PutImageScanningConfiguration",
            "ecr:PutImage",
            "ecr:ListImages",
            "ecr:InitiateLayerUpload",
            "ecr:GetRepositoryPolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:GetLifecyclePolicy",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetAuthorizationToken",
            "ecr:DescribeRepositories",
            "ecr:DescribeImages",
            "ecr:DescribeImageScanFindings",
            "ecr:DeleteLifecyclePolicy",
            "ecr:CompleteLayerUpload",
            "ecr:BatchGetImage",
            "ecr:BatchDeleteImage",
            "ecr:BatchCheckLayerAvailability",
          ]
          resources = ["*"]
        }
      ]
    }
  ]
}

// Typically when runs-on is installed, and we're using the embedded networking stack, we need a security group.
// This is a batties included optional feature.
module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  // Enabled if we are using the external networking stack and no security group ID is provided
  enabled = local.enabled && var.networking_stack == "external" && var.security_group_id == null

  // This cannot be local.vpc_id because that would create a dependency cycle - as the local.vpc_id is determined as the resulting VPC id.
  // The vpc_id is the created vpc by runs-on, or the one provided by the user if using the external networking stack.
  // Thus the security group ID (which is passed in as `ExternalVpcSecurityGroupId` as a parameter to the stack) cannot depend on the stacks' vpc_id.
  // `var.vpc_id` is safe to use here, because the networking_stack is required to be external for this.
  vpc_id = var.vpc_id

  context = module.this.context
}

resource "aws_security_group_rule" "this" {
  for_each = var.security_group_rules != null && local.enabled ? { for rule in var.security_group_rules : md5(jsonencode(rule)) => rule } : {}

  security_group_id = local.security_group_id

  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
}

module "cloudformation_stack" {
=======
  stack_name = coalesce(var.stack_name, module.this.name)
}

module "runs_on" {
>>>>>>> Stashed changes
  count = local.enabled ? 1 : 0

  source  = "runs-on/runs-on/aws"
  version = "v2.11.0-r1"

  # Stack configuration
  stack_name          = local.stack_name
  environment         = var.runs_on_environment
  cost_allocation_tag = var.cost_allocation_tag
  tags                = module.this.tags

  # GitHub configuration
  github_organization   = var.github_organization
  github_enterprise_url = var.github_enterprise_url
  license_key           = var.license_key

  # Alert configuration
  email                   = var.email
  alert_https_endpoint    = var.alert_https_endpoint
  alert_slack_webhook_url = var.alert_slack_webhook_url

  # Networking configuration
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  private_mode       = var.private_mode
  security_group_ids = var.security_group_ids

  # SSH configuration
  ssh_allowed    = var.ssh_allowed
  ssh_cidr_range = var.ssh_cidr_range

  # App Runner configuration
  app_image              = var.app_image
  app_tag                = var.app_tag
  bootstrap_tag          = var.bootstrap_tag
  app_cpu                = var.app_cpu
  app_memory             = var.app_memory
  app_debug              = var.app_debug
  app_ecr_repository_url = var.app_ecr_repository_url

  # Compute configuration
  log_retention_days               = var.log_retention_days
  permission_boundary_arn          = var.permission_boundary_arn
  detailed_monitoring_enabled      = var.detailed_monitoring_enabled
  ipv6_enabled                     = var.ipv6_enabled
  ebs_encryption_enabled           = var.ebs_encryption_enabled
  ebs_encryption_key_id            = var.ebs_encryption_key_id
  runner_default_disk_size         = var.runner_default_disk_size
  runner_default_volume_throughput = var.runner_default_volume_throughput
  runner_large_disk_size           = var.runner_large_disk_size
  runner_large_volume_throughput   = var.runner_large_volume_throughput

  # Runner configuration
  ec2_queue_size                  = var.ec2_queue_size
  runner_max_runtime              = var.runner_max_runtime
  runner_custom_tags              = var.runner_custom_tags
  runner_config_auto_extends_from = var.runner_config_auto_extends_from
  github_api_strategy             = var.github_api_strategy
  default_admins                  = var.default_admins
  spot_circuit_breaker            = var.spot_circuit_breaker

  # Storage configuration
  cache_expiration_days = var.cache_expiration_days
  force_destroy_buckets = var.force_destroy_buckets

  # Monitoring configuration
  enable_dashboard                           = var.enable_dashboard
  enable_cost_reports                        = var.enable_cost_reports
  app_alarm_daily_minutes                    = var.app_alarm_daily_minutes
  sqs_queue_oldest_message_threshold_seconds = var.sqs_queue_oldest_message_threshold_seconds

  # Integration configuration
  integration_step_security_api_key = var.integration_step_security_api_key
  otel_exporter_endpoint            = var.otel_exporter_endpoint
  otel_exporter_headers             = var.otel_exporter_headers
  logger_level                      = var.logger_level
  server_password                   = var.server_password

  # Optional features
  enable_efs                         = var.enable_efs
  enable_ecr                         = var.enable_ecr
  prevent_destroy_optional_resources = var.prevent_destroy_optional_resources
  force_delete_ecr                   = var.force_delete_ecr

  # WAF configuration
  enable_waf             = var.enable_waf
  waf_allowed_ipv4_cidrs = var.waf_allowed_ipv4_cidrs
  waf_allowed_ipv6_cidrs = var.waf_allowed_ipv6_cidrs
}

# Attach additional IAM policies to the EC2 instance role.
# Use this to grant runners access to services such as ECR, SSM, or custom resources.
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = local.enabled ? toset(var.additional_iam_policy_arns) : toset([])

  role       = one(module.runs_on[*].ec2_instance_role_name)
  policy_arn = each.value
}

# ---------------------------------------------------------------------------
# Data sources used for VPC-related outputs (e.g. TGW integration)
# ---------------------------------------------------------------------------

data "aws_vpc" "this" {
  count = local.enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_subnets" "private" {
  count = local.enabled ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

data "aws_subnets" "public" {
  count = local.enabled ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

data "aws_nat_gateways" "ngws" {
  count  = local.enabled ? 1 : 0
  vpc_id = var.vpc_id
}

# Look up the route table for each private subnet (used by TGW spoke component).
data "aws_route_table" "private" {
  for_each  = local.enabled && length(var.private_subnet_ids) > 0 ? toset(var.private_subnet_ids) : toset([])
  subnet_id = each.value
}

locals {
  all_private_subnet_ids  = one(data.aws_subnets.private[*].ids)
  all_public_subnet_ids   = one(data.aws_subnets.public[*].ids)
  vpc_cidr_block          = one(data.aws_vpc.this[*].cidr_block)
  private_route_table_ids = distinct([for rt in data.aws_route_table.private : rt.id])
}

# Validate that external networking variables are not set when using embedded networking.
# When networking_stack is "embedded", RunsOn creates its own VPC with subnets via CloudFormation,
# so providing external subnet IDs would be ignored and is likely a configuration error.

check "embedded_networking_no_vpc_id" {
  assert {
    condition     = var.networking_stack != "embedded" || var.vpc_id == null
    error_message = "vpc_id should not be set when networking_stack is 'embedded'. RunsOn creates its own VPC when using embedded networking."
  }
}

check "embedded_networking_no_subnet_ids" {
  assert {
    condition     = var.networking_stack != "embedded" || var.subnet_ids == null
    error_message = "subnet_ids should not be set when networking_stack is 'embedded'. RunsOn creates its own subnets when using embedded networking."
  }
}

check "embedded_networking_no_private_subnet_ids" {
  assert {
    condition     = var.networking_stack != "embedded" || var.private_subnet_ids == null
    error_message = "private_subnet_ids should not be set when networking_stack is 'embedded'. RunsOn creates its own subnets when using embedded networking."
  }
}

check "private_subnet_ids_template_version" {
  assert {
    condition     = var.private_subnet_ids == null || local.private_subnet_ids_supported
    error_message = "private_subnet_ids requires RunsOn CloudFormation template version 2.8.0 or newer. Please upgrade your template_url to a supported version."
  }
}
