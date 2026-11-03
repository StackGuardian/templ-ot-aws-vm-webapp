data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_iam_role" "instance" {
  name = "${var.name_prefix}-web"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name_prefix}-web"
  role = aws_iam_role.instance.name
}

resource "aws_security_group" "instance" {
  name        = "${var.name_prefix}-web"
  description = "Web instances"
  vpc_id      = aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "instance_from_alb" {
  #checkov:skip=CKV_AWS_260:False positive, the source is the load balancer security group, not 0.0.0.0/0
  security_group_id            = aws_security_group.instance.id
  description                  = "HTTP from the load balancer"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

# Outbound HTTPS only, for package installs and SSM.
resource "aws_vpc_security_group_egress_rule" "instance_https" {
  security_group_id = aws_security_group.instance.id
  description       = "HTTPS outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.name_prefix}-web-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  ebs_optimized = true
  user_data     = filebase64("${path.module}/user-data.sh")

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.instance.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 8
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.name_prefix}-web" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }
}

resource "aws_autoscaling_group" "web" {
  name                      = "${var.name_prefix}-web"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.min_size
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  # Apply waits until the instances are healthy behind the load balancer.
  wait_for_elb_capacity = var.min_size

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    precondition {
      condition     = var.min_size <= var.max_size
      error_message = "min_size must not be greater than max_size."
    }
  }

  depends_on = [aws_route_table_association.private]
}
