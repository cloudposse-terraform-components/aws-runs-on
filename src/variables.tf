variable "region" {
  type        = string
  description = "AWS Region"
}

# -----------------------------------------------------------------------------
# Required inputs
# -----------------------------------------------------------------------------

variable "github_organization" {
  type        = string
  description = "GitHub organization or username for RunsOn integration"
}

variable "license_key" {
  type        = string
  sensitive   = true
  description = "RunsOn license key. See https://runs-on.com/pricing/"
}

variable "email" {
  type        = string
  description = "Email address for RunsOn alert notifications"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for RunsOn deployment. RunsOn resources will be created in this VPC."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = <<-EOT
    Public subnet IDs for runners. At least one is required.
    Used for runners without the `private=true` label, or when `private_mode` is `"false"`.
  EOT
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "private_subnet_ids" {
  type        = list(string)
  description = <<-EOT
    Private subnet IDs for runners.
    Required when `private_mode` is not `"false"`. These subnets should have NAT gateway
    access for outbound connectivity.
  EOT
  default     = []
}

variable "private_mode" {
  type        = string
  description = <<-EOT
    Controls how runners are placed in subnets:
    - `"false"`: All runners use public subnets (default)
    - `"true"`: Private networking available; runners opt-in via `private=true` workflow label
    - `"always"`: Private networking is default; runners can opt-out
    - `"only"`: All runners MUST use private subnets
  EOT
  default     = "true"
  validation {
    condition     = contains(["false", "true", "always", "only"], var.private_mode)
    error_message = "private_mode must be one of: \"false\", \"true\", \"always\", \"only\"."
  }
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to use for runners. If not set and security_group_ids is empty, one will be created by the module."
  nullable    = true
  default     = null
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to use for runners. If empty and security_group_id is not set, one will be created by the module."
  default     = []
}

variable "security_group_rules" {
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "Additional security group rules to apply to the runner security group."
  nullable    = true
  default     = null
}

variable "ssh_allowed" {
  type        = bool
  description = "Whether SSH access is allowed to runners. Recommend false; use SSM instead."
  default     = false
}

variable "ssh_cidr_range" {
  type        = string
  description = "CIDR range for SSH access when ssh_allowed is true."
  default     = "0.0.0.0/0"
}

variable "ipv6_enabled" {
  type        = bool
  description = "Enable IPv6 support."
  default     = false
}

# -----------------------------------------------------------------------------
# Compute / App Runner
# -----------------------------------------------------------------------------

variable "app_cpu" {
  type        = number
  description = "CPU units for the RunsOn App Runner service."
  default     = 256
}

variable "app_memory" {
  type        = number
  description = "Memory in MB for the RunsOn App Runner service."
  default     = 512
}

variable "ebs_encryption_enabled" {
  type        = bool
  description = "Enable EBS encryption for runner volumes."
  default     = true
}

variable "runner_default_disk_size" {
  type        = number
  description = "Default EBS volume size in GB for runners."
  default     = 40
}

variable "runner_large_disk_size" {
  type        = number
  description = "EBS volume size in GB for runners using disk=large label."
  default     = 120
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days for runner logs."
  default     = 30
}

variable "permission_boundary_arn" {
  type        = string
  description = "IAM permissions boundary ARN for roles created by the module."
  default     = ""
}

# -----------------------------------------------------------------------------
# Runner configuration
# -----------------------------------------------------------------------------

variable "runner_custom_tags" {
  type        = list(string)
  description = "Custom tags for runner instances (e.g., [\"org=myorg\"])."
  default     = []
}

variable "runs_on_environment" {
  type        = string
  description = <<-EOT
    RunsOn environment identifier (e.g., "production").
    Note: This is the RunsOn environment, not the Cloud Posse context environment.
    If you run multiple RunsOn stacks in one organization, use different environments to segregate resources.
  EOT
  default     = "production"
}

variable "stack_name" {
  type        = string
  description = "Name for the RunsOn stack, used in resource naming. Defaults to the Cloud Posse module ID if not set."
  nullable    = true
  default     = null
}

# -----------------------------------------------------------------------------
# Optional features
# -----------------------------------------------------------------------------

variable "enable_efs" {
  type        = bool
  description = "Enable EFS shared storage for runners."
  default     = false
}

variable "enable_ecr" {
  type        = bool
  description = "Enable ECR image registry managed by RunsOn."
  default     = false
}

variable "enable_waf" {
  type        = bool
  description = "Enable WAF on the App Runner service."
  default     = false
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------

variable "cache_expiration_days" {
  type        = number
  description = "Number of days before S3 cache objects expire."
  default     = 10
}

variable "force_destroy_buckets" {
  type        = bool
  description = "Allow destruction of non-empty S3 buckets during teardown."
  default     = false
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "app_alarm_daily_minutes" {
  type        = number
  description = "Daily alarm threshold in minutes for App Runner usage."
  default     = 4000
}
