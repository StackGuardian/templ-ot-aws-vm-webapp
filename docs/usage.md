# AWS Web App on VMs (Auto Scaling + ALB)

Runs a small nginx web app on a group of EC2 servers behind an Application Load Balancer. Each server shows its own ID on the page, so reloading the page shows the load balancing at work.

Use it to show a classic, highly available web tier on virtual machines.

## What gets created

- A VPC across two availability zones, with public subnets for the load balancer and private subnets for the servers
- One NAT gateway, so the servers can install packages
- An Application Load Balancer with access logs in a private S3 bucket
- An Auto Scaling group with 2 to 4 Amazon Linux 2023 servers running nginx
- VPC flow logs in CloudWatch Logs

## Before you start

- A workflow with an AWS cloud connector for the target account
- Permissions to create VPC, EC2, Auto Scaling, load balancer, S3, IAM and CloudWatch Logs resources
- For HTTPS only: an ACM certificate in the same region

## Form fields

| Field | What it does | Default |
|---|---|---|
| Name prefix | Prefix for all resource names. 2 to 16 lowercase letters, digits or hyphens, starting with a letter | `demo` |
| Region | AWS region | `eu-central-1` |
| Tags | Extra tags added to all resources | none |
| VPC cidr | IP range of the new network | `10.0.0.0/16` |
| Instance type | Size of each server (x86_64) | `t3.micro` |
| Min size | Smallest number of servers | `2` |
| Max size | Largest number of servers | `4` |
| Allowed http cidrs | IP ranges that may reach the web app. Public by default | `0.0.0.0/0` |
| Certificate arn | Optional ACM certificate. With it, the app is served over HTTPS and HTTP redirects to HTTPS | empty |
| Deletion protection | Protects the load balancer from deletion. Keep it off for demos | off |
| Log retention days | How long access logs and flow logs are kept | `90` |

For a quick demo, keep all defaults.

## After the run

The workflow outputs show:

- `url`: open it in a browser and reload a few times
- `load_balancer_dns_name`: point a CNAME of your own domain here
- `autoscaling_group_name` and `access_logs_bucket`

The run waits until the servers are healthy behind the load balancer, which takes a few minutes. For a shell on a server, use Session Manager: `aws ssm start-session --target <instance_id> --region <region>`.

## Security defaults

- Servers have no public IPs and no SSH. They accept HTTP only from the load balancer
- Instance metadata requires IMDSv2. Disks are encrypted
- With a certificate: modern TLS policy (TLS 1.2 and 1.3)
- The log bucket is private, encrypted and accepts only TLS

## Cost and cleanup

The load balancer, the NAT gateway and the servers are billed per hour, also when idle. Destroy the resources from the workflow when the demo is over.

## Limits

- One NAT gateway, so outbound traffic is not highly available
- No WAF
