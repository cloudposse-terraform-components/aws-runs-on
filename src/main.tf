locals {
  enabled = module.this.enabled

  # Merge singular security_group_id with security_group_ids list for backward compatibility
  security_group_ids = compact(concat(
    var.security_group_ids,
    var.security_group_id != null ? [var.security_group_id] : []
  ))

  # Use module.this.id as stack_name if not explicitly set
  stack_name = var.stack_name != null ? var.stack_name : module.this.id
}

module "runs_on" {
  count = local.enabled ? 1 : 0

  source  = "runs-on/runs-on/aws"
  version = "2.11.0-r1"

  # Required inputs
  github_organization = var.github_organization
  license_key         = var.license_key
  vpc_id              = var.vpc_id
  public_subnet_ids   = var.public_subnet_ids
  email               = var.email

  # Networking
  private_subnet_ids = var.private_subnet_ids
  private_mode       = var.private_mode
  security_group_ids = local.security_group_ids
  ssh_allowed        = var.ssh_allowed
  ssh_cidr_range     = var.ssh_cidr_range
  ipv6_enabled       = var.ipv6_enabled

  # Compute / App Runner
  app_cpu                  = var.app_cpu
  app_memory               = var.app_memory
  ebs_encryption_enabled   = var.ebs_encryption_enabled
  runner_large_disk_size   = var.runner_large_disk_size
  runner_default_disk_size = var.runner_default_disk_size
  log_retention_days       = var.log_retention_days
  permission_boundary_arn  = var.permission_boundary_arn

  # Runner configuration
  runner_custom_tags = var.runner_custom_tags

  # Naming / environment
  stack_name  = local.stack_name
  environment = var.runs_on_environment

  # Monitoring
  app_alarm_daily_minutes = var.app_alarm_daily_minutes

  # Optional features
  enable_efs = var.enable_efs
  enable_ecr = var.enable_ecr
  enable_waf = var.enable_waf

  # Storage
  cache_expiration_days = var.cache_expiration_days
  force_destroy_buckets = var.force_destroy_buckets

  # Tags - pass Cloud Posse context tags
  tags = module.this.tags
}

# -----------------------------------------------------------------------------
# Custom ECR IAM policy for runner instances
# This grants runners access to existing ECR repositories in the account,
# independent of the module's enable_ecr feature (which creates a new repo).
# -----------------------------------------------------------------------------

module "iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.2"

  context = module.this.context
  enabled = local.enabled

  iam_policy_enabled = true
  iam_policy = [
    {
      version   = "2012-10-17"
      policy_id = "RunsOnECRAccess"
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

# Attach the custom ECR policy to the module's EC2 instance role
resource "aws_iam_role_policy_attachment" "ecr_custom" {
  count = local.enabled ? 1 : 0

  role       = one(module.runs_on[*].ec2_instance_role_name)
  policy_arn = module.iam_policy.policy_arn
}

# -----------------------------------------------------------------------------
# Additional security group rules
# Applied to the first security group from the module's output.
# The module auto-creates a SG (with all outbound + optional SSH) when
# security_group_ids is empty; these rules add to that SG.
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "this" {
  for_each = var.security_group_rules != null && local.enabled ? {
    for rule in var.security_group_rules : md5(jsonencode(rule)) => rule
  } : {}

  security_group_id = one(module.runs_on[*].security_group_ids[0])

  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
}

# -----------------------------------------------------------------------------
# Data sources for TGW-compatible outputs
# -----------------------------------------------------------------------------

data "aws_vpc" "this" {
  count = local.enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_nat_gateways" "ngws" {
  count  = local.enabled ? 1 : 0
  vpc_id = var.vpc_id
}
