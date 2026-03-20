variable "region" {
  type        = string
  description = "AWS Region"
}

# ---------------------------------------------------------------------------
# Stack / identity
# ---------------------------------------------------------------------------

variable "stack_name" {
  type        = string
  description = "Name for the RunsOn stack used for resource naming. Defaults to the CloudPosse component name (e.g. `runs-on`)."
  nullable    = true
  default     = null

  validation {
    condition     = var.stack_name == null || can(regex("^[a-z0-9-]+$", var.stack_name))
    error_message = "stack_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "runs_on_environment" {
  type        = string
  description = "RunsOn environment name used for resource tagging and job label filtering. Workflows must include `env:<value>` in the `runs-on` label when this is not `production`. See https://runs-on.com/configuration/environments/ for details."
  default     = "production"
}

variable "cost_allocation_tag" {
  type        = string
  description = "Name of the tag key used for cost allocation and tracking."
  default     = "stack"
}

# ---------------------------------------------------------------------------
# GitHub
# ---------------------------------------------------------------------------

variable "github_organization" {
  type        = string
  description = "GitHub organization or username for RunsOn integration."
}

variable "github_enterprise_url" {
  type        = string
  description = "GitHub Enterprise Server URL. Leave empty for github.com."
  default     = ""
}

variable "license_key" {
  type        = string
  description = "RunsOn license key obtained from runs-on.com."
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Alerts
# ---------------------------------------------------------------------------

variable "email" {
  type        = string
  description = "Email address for alerts and notifications. An SNS subscription confirmation email will be sent to this address."
}

variable "alert_https_endpoint" {
  type        = string
  description = "HTTPS endpoint for alert notifications (optional)."
  default     = ""
}

variable "alert_slack_webhook_url" {
  type        = string
  description = "Slack webhook URL for alert notifications (optional)."
  default     = ""
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
<<<<<<< Updated upstream
  description = <<-EOT
    VPC ID for external networking (maps to ExternalVpcId).

    This variable only applies when using `networking_stack = "external"` (bring your own VPC).
    When using `networking_stack = "embedded"`, RunsOn creates its own VPC via CloudFormation,
    so this variable should not be set.
  EOT
  nullable    = true
  default     = null
=======
  description = "VPC ID where RunsOn infrastructure will be deployed. Must be an existing VPC — RunsOn no longer manages its own VPC."
>>>>>>> Stashed changes
}

variable "public_subnet_ids" {
  type        = list(string)
<<<<<<< Updated upstream
  description = <<-EOT
    Public subnet IDs for runners (maps to ExternalVpcPublicSubnetIds).

    This variable only applies when using `networking_stack = "external"` (bring your own VPC).
    When using `networking_stack = "embedded"`, RunsOn creates its own VPC with public and private
    subnets via CloudFormation, so this variable should not be set.

    Used for runners without the `private=true` label, or when `Private` parameter is set to `"false"`.
  EOT
  nullable    = true
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = <<-EOT
    Private subnet IDs for runners (maps to ExternalVpcPrivateSubnetIds).

    This variable only applies when using `networking_stack = "external"` (bring your own VPC).
    When using `networking_stack = "embedded"`, RunsOn creates its own VPC with public and private
    subnets via CloudFormation, so this variable should not be set.

    Required when using external networking with `Private: "true"` or `Private: "always"` to place
    runners in private subnets. These subnets should have NAT gateway access for outbound connectivity.
  EOT
  nullable    = true
  default     = null
=======
  description = "List of public subnet IDs for runner instances. At least one is required."
>>>>>>> Stashed changes
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for runner instances. Required when `private_mode` is not `false`."
  default     = []
}

variable "private_mode" {
  type        = string
  description = "Private networking mode for runners. `false` = public subnets only; `true` = opt-in via `private=true` workflow label; `always` = private by default, opt-out with `private=false` label; `only` = private subnets forced, no public option. Fixes the CloudFormation behavior where `Private = true` required `Private = always` to actually place runners in private subnets."
  default     = "false"

  validation {
    condition     = contains(["false", "true", "always", "only"], var.private_mode)
    error_message = "private_mode must be one of: false, true, always, only."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for runner instances and the App Runner service. If empty, a security group will be created automatically."
  default     = []
}

variable "ssh_allowed" {
  type        = bool
  description = "Allow SSH access to runner instances. Disable this to reduce attack surface — use Session Manager (SSM) for console access instead."
  default     = false
}

variable "ssh_cidr_range" {
  type        = string
  description = "CIDR range allowed for SSH access. Only applies when `ssh_allowed` is `true`."
  default     = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# App Runner
# ---------------------------------------------------------------------------

variable "app_image" {
  type        = string
  description = "App Runner container image for the RunsOn service. Defaults to the image bundled with the module version."
  default     = "public.ecr.aws/c5h5o9k1/runs-on/runs-on:v2.11.0@sha256:875bcd8a36be7be78509a4c8371cdb4bff01af06c49f4a2d2a2647e3bf44bac5"
}

variable "app_tag" {
  type        = string
  description = "Application version tag for the RunsOn service."
  default     = "v2.11.0"
}

variable "bootstrap_tag" {
  type        = string
  description = "Bootstrap script version tag."
  default     = "v0.1.12"
}

variable "app_cpu" {
  type        = number
  description = "CPU units for the App Runner service. Valid values: 256, 512, 1024, 2048, 4096."
  default     = 256
}

variable "app_memory" {
  type        = number
  description = "Memory in MB for the App Runner service. Valid values: 512, 1024, 2048, 3072, 4096, 6144, 8192, 10240, 12288."
  default     = 512
}

variable "app_debug" {
  type        = bool
  description = "Enable debug mode for the RunsOn stack. Prevents auto-shutdown of failed runner instances."
  default     = false
}

variable "app_ecr_repository_url" {
  type        = string
  description = "Private ECR repository URL for the RunsOn App Runner image (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:tag`). When specified, App Runner pulls from this private ECR instead of public ECR."
  default     = ""
}

# ---------------------------------------------------------------------------
# Compute / EC2
# ---------------------------------------------------------------------------

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain CloudWatch logs for EC2 runner instances."
  default     = 7
}

variable "permission_boundary_arn" {
  type        = string
  description = "IAM permissions boundary ARN to attach to all IAM roles created by the module (optional)."
  default     = ""
}

variable "detailed_monitoring_enabled" {
  type        = bool
  description = "Enable detailed CloudWatch monitoring for EC2 runner instances (increases costs)."
  default     = false
}

variable "ipv6_enabled" {
  type        = bool
  description = "Enable IPv6 support for runner instances."
  default     = false
}

variable "ebs_encryption_enabled" {
  type        = bool
  description = "Enable encryption for EBS volumes on runner instances."
  default     = false
}

variable "ebs_encryption_key_id" {
  type        = string
  description = "KMS key ID for EBS volume encryption. Leave empty to use the AWS managed key."
  default     = ""
}

variable "runner_default_disk_size" {
  type        = number
  description = "Default EBS volume size in GB for runner instances (8–16384)."
  default     = 40
}

variable "runner_default_volume_throughput" {
  type        = number
  description = "Default EBS volume throughput in MiB/s for gp3 volumes (125–2000)."
  default     = 400
}

variable "runner_large_disk_size" {
  type        = number
  description = "Large EBS volume size in GB for runners requiring more storage, e.g. `disk=large` label (20–16384)."
  default     = 80
}

variable "runner_large_volume_throughput" {
  type        = number
  description = "Large EBS volume throughput in MiB/s for gp3 volumes (125–2000)."
  default     = 750
}

# ---------------------------------------------------------------------------
# Runner behaviour
# ---------------------------------------------------------------------------

variable "ec2_queue_size" {
  type        = number
  description = "Maximum number of EC2 instances kept warm in the queue (1–1000)."
  default     = 2
}

variable "runner_max_runtime" {
  type        = number
  description = "Maximum runtime in minutes for a runner before it is forcibly terminated."
  default     = 720
}

variable "runner_custom_tags" {
  type        = list(string)
  description = "Custom tags to apply to runner instances."
  default     = []
}

variable "runner_config_auto_extends_from" {
  type        = string
  description = "Base runner configuration file that new configs automatically extend from."
  default     = ".github-private"
}

variable "github_api_strategy" {
  type        = string
  description = "Strategy for GitHub API calls. `normal` or `conservative` (reduces API usage)."
  default     = "normal"
}

variable "default_admins" {
  type        = string
  description = "Comma-separated list of GitHub usernames to grant admin access to the RunsOn server."
  default     = ""
}

variable "spot_circuit_breaker" {
  type        = string
  description = "Spot instance circuit breaker config (format: `failures/window_minutes/block_minutes`). Example: `2/15/30` = 2 failures in 15 min → block for 30 min."
  default     = "2/15/30"
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

variable "cache_expiration_days" {
  type        = number
  description = "Number of days to retain cache artifacts in S3 before expiration (1–365)."
  default     = 10
}

variable "force_destroy_buckets" {
  type        = bool
  description = "Allow S3 buckets to be destroyed even when non-empty. Set to `false` in production to prevent accidental data loss."
  default     = false
}

# ---------------------------------------------------------------------------
# Monitoring & alarms
# ---------------------------------------------------------------------------

variable "enable_dashboard" {
  type        = bool
  description = "Create a CloudWatch dashboard for monitoring RunsOn operations."
  default     = true
}

variable "enable_cost_reports" {
  type        = bool
  description = "Send automated cost reports to the alert email address."
  default     = true
}

variable "app_alarm_daily_minutes" {
  type        = number
  description = "Daily App Runner budget in minutes before a CloudWatch alarm fires."
  default     = 4000
}

variable "sqs_queue_oldest_message_threshold_seconds" {
  type        = number
  description = "Threshold in seconds for the oldest SQS message age before a CloudWatch alarm fires. Set to 0 to disable."
  default     = 0
}

# ---------------------------------------------------------------------------
# Integrations
# ---------------------------------------------------------------------------

variable "integration_step_security_api_key" {
  type        = string
  description = "API key for StepSecurity integration (optional)."
  default     = ""
  sensitive   = true
}

variable "otel_exporter_endpoint" {
  type        = string
  description = "OpenTelemetry exporter endpoint for observability (optional)."
  default     = ""
}

variable "otel_exporter_headers" {
  type        = string
  description = "OpenTelemetry exporter headers (optional)."
  default     = ""
  sensitive   = true
}

variable "logger_level" {
  type        = string
  description = "Logging level for the RunsOn service. One of: `debug`, `info`, `warn`, `error`."
  default     = "info"
}

variable "server_password" {
  type        = string
  description = "Password for the RunsOn server admin interface (optional)."
  default     = ""
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Optional features
# ---------------------------------------------------------------------------

variable "enable_efs" {
  type        = bool
  description = "Enable an EFS file system for shared storage across runners."
  default     = false
}

variable "enable_ecr" {
  type        = bool
  description = "Enable an ECR repository for ephemeral Docker image storage."
  default     = false
}

variable "prevent_destroy_optional_resources" {
  type        = bool
  description = "Prevent destruction of EFS and ECR resources. Set to `true` in production to protect against accidental data loss."
  default     = true
}

variable "force_delete_ecr" {
  type        = bool
  description = "Allow the ECR repository to be deleted even when it contains images. For testing environments only."
  default     = false
}

# ---------------------------------------------------------------------------
# WAF
# ---------------------------------------------------------------------------

variable "enable_waf" {
  type        = bool
  description = "Enable AWS WAF for the App Runner service. When enabled, access is restricted to GitHub webhook IPs plus any explicitly allowed CIDRs. **Note:** Enable WAF only after completing the GitHub App registration, as WAF blocks the initial setup UI."
  default     = false
}

variable "waf_allowed_ipv4_cidrs" {
  type        = list(string)
  description = "Additional IPv4 CIDR blocks to allow through WAF (besides GitHub webhook IPs)."
  default     = []
}

variable "waf_allowed_ipv6_cidrs" {
  type        = list(string)
  description = "Additional IPv6 CIDR blocks to allow through WAF (besides GitHub webhook IPs)."
  default     = []
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

variable "additional_iam_policy_arns" {
  type        = list(string)
  description = "List of IAM managed policy ARNs to attach to the EC2 runner instance role. Use this to grant runners access to services such as ECR, SSM Parameter Store, or other AWS resources required by your workflows."
  default     = []
}
