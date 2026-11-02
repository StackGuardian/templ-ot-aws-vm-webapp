output "url" {
  description = "URL of the web app"
  value       = "${local.https ? "https" : "http"}://${aws_lb.this.dns_name}"
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer, also the DNS target for a custom domain"
  value       = aws_lb.this.dns_name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group"
  value       = aws_autoscaling_group.web.name
}

output "access_logs_bucket" {
  description = "S3 bucket with the load balancer access logs"
  value       = aws_s3_bucket.alb_logs.id
}
