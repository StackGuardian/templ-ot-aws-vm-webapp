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
- Permissions to create VPC, EC2, Auto Scaling, load balancer, S3, IAM and CloudWatch Logs resources. This includes `iam:PassRole` for the instance profile and the flow log role, and `ec2:DescribeInstanceTypeOfferings`, which the run uses to pick zones that offer your instance type
- For HTTPS only: an ACM certificate in the same region

## Form fields

| Field | What it does | Default |
|---|---|---|
| Name Prefix | Prefix for all resource names. 2 to 16 lowercase letters, digits or hyphens, starting with a letter | `demo` |
| Region | AWS region | `eu-central-1` |
| Instance Type | Size of each server (x86_64). The list has general-purpose and burstable types | `t3.micro` (2 vCPU, 1 GiB) |

**Advanced settings** (tick "Show advanced settings" to change them):

| Field | What it does | Default |
|---|---|---|
| VPC CIDR | IP range of the new network | `10.0.0.0/16` |
| Min Size | Smallest number of servers, 1 to 10. Also the number started at first | `2` |
| Max Size | Largest number of servers, 1 to 20. Must not be below Min Size | `4` |
| Allowed HTTP CIDRs | IP ranges that may reach the web app. Public by default | `0.0.0.0/0` |
| Certificate ARN | Optional ACM certificate. With it, the app is served over HTTPS and HTTP redirects to HTTPS | empty |
| Deletion Protection | Protects the load balancer from deletion. Keep it off for demos | off |
| Log Retention Days | How long access logs and flow logs are kept. CloudWatch Logs allows only fixed values | `90` |
| Tags | Extra tags added to all resources | none |

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

- The server image is chosen once, when the deployment is created. A later run does not replace the servers when Amazon publishes a newer image. To move to a newer image, destroy the deployment and deploy it again
- The two zones are the first two in the region that offer your instance type. If fewer than two do, the run stops with a message before anything is created

- One NAT gateway, so outbound traffic is not highly available
- No WAF
