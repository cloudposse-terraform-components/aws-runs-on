locals {
  enabled = module.this.enabled

  vpc_id                     = var.vpc_id != null ? { "ExternalVpcId" = var.vpc_id } : {}
  networking_stack           = var.networking_stack != null ? { "NetworkingStack" = var.networking_stack } : {}
  subnet_ids                 = var.subnet_ids != null ? { "ExternalVpcSubnetIds" = var.subnet_ids } : {}
  external_security_group_id = var.security_group_id != null ? { "ExternalVpcSecurityGroupId" = var.security_group_id } : {}
  created_security_group_id  = var.security_group_id == null && var.networking_stack == "external" ? { "ExternalVpcSecurityGroupId" = module.security_group.id } : {}

  parameters = merge({
    "EC2InstanceCustomPolicy" = module.iam_policy.policy_arn
    }, var.parameters
    , local.networking_stack
    , local.vpc_id
    , local.subnet_ids
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

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  enabled = local.enabled && var.security_group_id == null && var.networking_stack == "external"

  vpc_id = local.vpc_id

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

locals {
  vpc_id         = one(module.cloudformation_stack[*].outputs["RunsOnVPCId"])
  vpc_cidr_block = one(module.cloudformation_stack[*].outputs["RunsOnVpcCidrBlock"])
  public_subnet_ids = compact([
    one(module.cloudformation_stack[*].outputs["RunsOnPublicSubnet1"]),
    one(module.cloudformation_stack[*].outputs["RunsOnPublicSubnet2"]),
    one(module.cloudformation_stack[*].outputs["RunsOnPublicSubnet3"]),
  ])
  private_subnet_ids = compact([
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateSubnet1"]),
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateSubnet2"]),
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateSubnet3"]),
  ])
  private_route_table_ids = compact([
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateRouteTable1Id"]),
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateRouteTable2Id"]),
    one(module.cloudformation_stack[*].outputs["RunsOnPrivateRouteTable3Id"]),
  ])
  security_group_id = one(module.cloudformation_stack[*].outputs["RunsOnSecurityGroupId"])
}

data "aws_nat_gateways" "ngws" {
  count  = local.enabled ? 1 : 0
  vpc_id = local.vpc_id
}
