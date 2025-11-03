locals {
  enabled = module.this.enabled

  external_vpc_id         = var.vpc_id != null ? { "ExternalVpcId" = var.vpc_id } : {}
  networking_stack        = var.networking_stack != null ? { "NetworkingStack" = var.networking_stack } : {}
  subnet_ids              = concat(coalesce(var.public_subnet_ids, []), coalesce(var.private_subnet_ids, []))
  external_vpc_subnet_ids = length(local.subnet_ids) > 0 ? { "ExternalVpcSubnetIds" = join(",", local.subnet_ids) } : {}
  // If var.security_group_id is provided, we use it. Otherwise, if we are using the external networking stack, we create one.
  external_security_group_id = var.security_group_id != null ? { "ExternalVpcSecurityGroupId" = var.security_group_id } : {}
  // If var.security_group_id is not provided and we are using the external networking stack, we create one.
  created_security_group_id = var.security_group_id == null && var.networking_stack == "external" ? { "ExternalVpcSecurityGroupId" = module.security_group.id } : {}

  parameters = merge({
    "EC2InstanceCustomPolicy" = module.iam_policy.policy_arn
    }, var.parameters
    , local.networking_stack
    , local.external_vpc_id
    , local.external_vpc_subnet_ids
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
  count = local.enabled ? 1 : 0

  source  = "cloudposse/cloudformation-stack/aws"
  version = "0.7.1"

  enabled = var.enabled
  context = module.this.context

  template_url       = var.template_url
  parameters         = local.parameters
  capabilities       = var.capabilities
  on_failure         = var.on_failure
  timeout_in_minutes = var.timeout_in_minutes
  policy_body        = var.policy_body

  depends_on = [module.iam_policy]
}

data "aws_vpc" "this" {
  count = local.enabled ? 1 : 0
  id    = local.vpc_id
}

data "aws_subnets" "private" {
  count = local.enabled ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
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
    values = [local.vpc_id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

locals {
  vpc_id             = var.networking_stack == "embedded" ? one(module.cloudformation_stack[*].outputs["RunsOnVPCId"]) : var.vpc_id
  vpc_cidr_block     = var.networking_stack == "embedded" ? one(module.cloudformation_stack[*].outputs["RunsOnVpcCidrBlock"]) : one(data.aws_vpc.this[*].cidr_block)
  public_subnet_ids  = one(data.aws_subnets.public[*].ids)
  private_subnet_ids = one(data.aws_subnets.private[*].ids)
  private_route_table_ids = var.networking_stack == "embedded" ? compact([
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateRouteTable1Id"]),
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateRouteTable2Id"]),
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateRouteTable3Id"]),
  ]) : []
  security_group_id = one(module.cloudformation_stack[*].outputs["RunsOnSecurityGroupId"])
}

data "aws_nat_gateways" "ngws" {
  count  = local.enabled ? 1 : 0
  vpc_id = local.vpc_id
}
