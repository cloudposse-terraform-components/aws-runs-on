variable "region" {
  type        = string
  description = "AWS Region"
}

variable "template_url" {
  type        = string
  description = "Amazon S3 bucket URL location of a file containing the CloudFormation template body. Maximum file size: 460,800 bytes"
}

variable "parameters" {
  type        = map(string)
  description = "Key-value map of input parameters for the Stack Set template. (_e.g._ map(\"BusinessUnit\",\"ABC\")"
  default     = {}
}

variable "capabilities" {
  type        = list(string)
  description = "A list of capabilities. Valid values: CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_AUTO_EXPAND"
  default     = []
}

variable "on_failure" {
  type        = string
  default     = "ROLLBACK"
  description = "Action to be taken if stack creation fails. This must be one of: `DO_NOTHING`, `ROLLBACK`, or `DELETE`"
}

variable "timeout_in_minutes" {
  type        = number
  default     = 30
  description = "The amount of time that can pass before the stack status becomes `CREATE_FAILED`"
}

variable "policy_body" {
  type        = string
  default     = ""
  description = "Structure containing the stack policy body"
}

variable "networking_stack" {
  type        = string
  description = "Let RunsOn manage your networking stack (`embedded`), or use a vpc under your control (`external`). Null will default to whatever the template used as default. If you select `external`, you will need to provide the VPC ID, the subnet IDs, and optionally the security group ID, and make sure your whole networking setup is compatible with RunsOn (see https://runs-on.com/networking/embedded-vs-external/ for more details). To get started quickly, we recommend using the 'embedded' option."
  nullable    = true
  default     = "embedded"
  validation {
    condition     = contains(["embedded", "external"], var.networking_stack) || var.networking_stack == null
    error_message = "Networking stack must be either `embedded` or `external`."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
  nullable    = true
  default     = null
  validation {
    condition     = var.networking_stack != "external" || var.vpc_id != null
    error_message = "VPC ID is required when networking stack is `external`."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
  nullable    = true
  default     = null
  validation {
    condition     = var.networking_stack != "external" || var.subnet_ids != null && length(var.subnet_ids) > 0
    error_message = "Subnet IDs are required when networking stack is `external`."
  }
}

variable "security_group_id" {
  type        = string
  description = "Security group ID. If not set, a new security group will be created."
  nullable    = true
  default     = null
}

variable "security_group_rules" {
  type        = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "Security group rules. These are either added to the security passed in, or added to the security group created when var.security_group_id is not set. Types include `ingress` and `egress`."
  nullable    = true
  default     = null
}