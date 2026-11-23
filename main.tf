locals {
  tags = merge(
    {
      Project     = var.name_prefix
      Environment = "demo"
      ManagedBy   = "opentofu"
      Repository  = "tf-aws-vm-webapp"
    },
    var.advanced_settings.tags,
  )

  # An empty field in the form must count as "no certificate", like null.
  certificate_arn = var.advanced_settings.certificate_arn == "" ? null : var.advanced_settings.certificate_arn

  # The first two zones that offer the instance type (the load balancer needs two).
  # Not every zone offers every type. Empty when fewer than two zones offer it.
  offered_azs = [for z in data.aws_availability_zones.available.names : z if contains(data.aws_ec2_instance_type_offerings.this.locations, z)]
  azs         = length(local.offered_azs) >= 2 ? slice(local.offered_azs, 0, 2) : []
}
