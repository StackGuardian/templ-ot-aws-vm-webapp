# Unit tests: plan only, providers are mocked. No cloud account, no cost.
# Run: tofu test -test-directory=tests/unit
# Test case catalog: tests/README.md

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-central-1a", "eu-central-1b"]
    }
  }

  mock_data "aws_elb_service_account" {
    defaults = {
      arn = "arn:aws:iam::054676820928:root"
    }
  }

  # Some arguments are validated as ARNs, so mocked values must look like ARNs.
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-central-1:123456789012:log-group:mock"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock"
    }
  }

  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn = "arn:aws:iam::123456789012:instance-profile/mock"
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      arn      = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/mock/0123456789abcdef"
      dns_name = "mock-alb.eu-central-1.elb.amazonaws.com"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/mock/0123456789abcdef"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mock-alb-logs"
    }
  }

  mock_resource "aws_launch_template" {
    defaults = {
      id             = "lt-0123456789abcdef0"
      latest_version = 1
    }
  }
}

# U-01
run "defaults_are_valid" {
  command = plan

  assert {
    condition = (
      local.tags["Environment"] == "demo" &&
      local.tags["ManagedBy"] == "opentofu" &&
      local.tags["Project"] == var.name_prefix &&
      local.tags["Repository"] != ""
    )
    error_message = "Default tags are missing or wrong."
  }
}

# U-02
run "invalid_name_prefix_is_rejected" {
  command = plan

  variables {
    name_prefix = "Invalid_Prefix"
  }

  expect_failures = [var.name_prefix]
}

# U-03
run "custom_tags_are_merged" {
  command = plan

  variables {
    tags = {
      Owner = "tester"
    }
  }

  assert {
    condition     = local.tags["Owner"] == "tester" && local.tags["ManagedBy"] == "opentofu"
    error_message = "Custom tags are not merged with the default tags."
  }
}

# U-04
run "instances_have_no_public_ip" {
  command = apply

  assert {
    condition     = !one(aws_launch_template.web.network_interfaces).associate_public_ip_address
    error_message = "Instances must not get public IPs."
  }

  assert {
    condition     = toset(aws_autoscaling_group.web.vpc_zone_identifier) == toset(aws_subnet.private[*].id)
    error_message = "The Auto Scaling group must use only the private subnets."
  }
}

# U-05
run "imdsv2_and_encryption_are_enforced" {
  command = apply

  assert {
    condition     = one(aws_launch_template.web.metadata_options).http_tokens == "required"
    error_message = "IMDSv2 must be enforced."
  }

  assert {
    condition     = one(one(aws_launch_template.web.block_device_mappings).ebs).encrypted == "true"
    error_message = "EBS volumes must be encrypted."
  }
}

# U-06
run "instances_accept_traffic_only_from_alb" {
  command = apply

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.instance_from_alb.referenced_security_group_id == aws_security_group.alb.id &&
      aws_vpc_security_group_ingress_rule.instance_from_alb.cidr_ipv4 == null
    )
    error_message = "Instances must accept traffic only from the load balancer security group."
  }
}

# U-07
run "load_balancer_is_hardened" {
  command = apply

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields
    error_message = "The load balancer must drop invalid header fields."
  }

  assert {
    condition     = one(aws_lb.this.access_logs).enabled && one(aws_lb.this.access_logs).bucket == aws_s3_bucket.alb_logs.id
    error_message = "Access logs must be enabled."
  }

  assert {
    condition     = toset(aws_lb.this.subnets) == toset(aws_subnet.public[*].id)
    error_message = "The load balancer must be in the public subnets."
  }
}

# U-08
run "https_redirect_with_certificate" {
  command = apply

  variables {
    certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/mock"
  }

  assert {
    condition     = one(aws_lb_listener.http.default_action).type == "redirect" && one(one(aws_lb_listener.http.default_action).redirect).protocol == "HTTPS"
    error_message = "With a certificate, HTTP must redirect to HTTPS."
  }

  assert {
    condition     = length(aws_lb_listener.https) == 1 && aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "The HTTPS listener must use a TLS 1.2+ policy."
  }

  assert {
    condition     = startswith(output.url, "https://")
    error_message = "The URL must use HTTPS when a certificate is set."
  }
}

# U-09
run "log_bucket_is_private_and_encrypted" {
  command = apply

  assert {
    condition = (
      aws_s3_bucket_public_access_block.alb_logs.block_public_acls &&
      aws_s3_bucket_public_access_block.alb_logs.block_public_policy &&
      aws_s3_bucket_public_access_block.alb_logs.ignore_public_acls &&
      aws_s3_bucket_public_access_block.alb_logs.restrict_public_buckets
    )
    error_message = "The log bucket must block public access."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.alb_logs.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "The log bucket must be encrypted."
  }
}

# U-10
run "vpc_flow_logs_are_enabled" {
  command = apply

  assert {
    condition     = aws_flow_log.this.traffic_type == "ALL"
    error_message = "VPC flow logs must capture all traffic."
  }
}
