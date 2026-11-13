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
}
