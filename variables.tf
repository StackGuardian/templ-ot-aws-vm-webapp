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

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "instance_type" {
  description = "EC2 instance type (x86_64)"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 1
    error_message = "At least one instance is needed."
  }
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

variable "allowed_http_cidrs" {
  description = "IPv4 CIDRs allowed to reach the load balancer. The web app is public by default."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.allowed_http_cidrs : can(cidrnetmask(c))])
    error_message = "All entries must be valid IPv4 CIDR blocks."
  }
}

variable "certificate_arn" {
  description = "Optional ACM certificate for HTTPS on the load balancer. Without it the app is served over HTTP only."
  type        = string
  default     = null

  validation {
    condition     = var.certificate_arn == null || can(regex("^arn:aws[a-z-]*:acm:", var.certificate_arn))
    error_message = "Must be an ACM certificate ARN."
  }
}

variable "deletion_protection" {
  description = "Protect the load balancer from deletion. Off by default so the demo can be destroyed."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Retention of load balancer access logs and VPC flow logs"
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "CloudWatch Logs accepts only fixed retention values, for example 30, 90 or 365."
  }
}
