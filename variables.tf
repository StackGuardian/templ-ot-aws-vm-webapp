variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.name_prefix))
    error_message = "Use 2-16 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type (x86_64)"
  type        = string
  default     = "t3.micro"
}

# Grouped so the StackGuardian form can show them in one "Advanced Settings" section.
variable "advanced_settings" {
  description = "Settings most deployments keep at their defaults"
  type = object({
    vpc_cidr            = optional(string, "10.0.0.0/16")       # CIDR block of the VPC
    min_size            = optional(number, 2)                   # Minimum number of instances
    max_size            = optional(number, 4)                   # Maximum number of instances
    allowed_http_cidrs  = optional(list(string), ["0.0.0.0/0"]) # IPv4 CIDRs allowed to reach the load balancer, public by default
    certificate_arn     = optional(string)                      # Optional ACM certificate for HTTPS. Without it the app is served over HTTP only.
    deletion_protection = optional(bool, false)                 # Protect the load balancer from deletion. Off by default so the demo can be destroyed.
    log_retention_days  = optional(number, 90)                  # Retention of load balancer access logs and VPC flow logs
    tags                = optional(map(string), {})             # Additional tags for all resources
  })
  default  = {}
  nullable = false

  validation {
    condition     = can(cidrnetmask(var.advanced_settings.vpc_cidr))
    error_message = "Must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = var.advanced_settings.min_size >= 1 && var.advanced_settings.min_size <= 10
    error_message = "min_size must be between 1 and 10."
  }

  validation {
    condition     = var.advanced_settings.max_size >= 1 && var.advanced_settings.max_size <= 20
    error_message = "max_size must be between 1 and 20."
  }

  validation {
    condition     = alltrue([for c in var.advanced_settings.allowed_http_cidrs : can(cidrnetmask(c))])
    error_message = "All entries must be valid IPv4 CIDR blocks."
  }

  validation {
    condition     = var.advanced_settings.certificate_arn == null || var.advanced_settings.certificate_arn == "" || can(regex("^arn:aws[a-z-]*:acm:", var.advanced_settings.certificate_arn))
    error_message = "Must be an ACM certificate ARN."
  }

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.advanced_settings.log_retention_days)
    error_message = "CloudWatch Logs accepts only fixed retention values, for example 30, 90 or 365."
  }
}
