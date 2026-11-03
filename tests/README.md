# Tests

Tests use the built-in OpenTofu test framework (`tofu test`, OpenTofu 1.8 or later).

| Level | Folder | What it does | Cost | When it runs |
|---|---|---|---|---|
| Unit | `tests/unit` | Plan only with mocked providers. Checks configuration and security settings. | None | Merge requests into `development` or `main`, and tags |
| Integration | `tests/integration` | Deploys real resources, checks them, destroys them. | Cloud cost while running | Tags, when cloud credentials are set (`integration-tests` job) |

## Run locally

```bash
tofu init
tofu test -test-directory=tests/unit
tofu test -test-directory=tests/integration   # needs cloud credentials
```

## Test cases

| ID | Level | Description | Status |
|---|---|---|---|
| U-01 | Unit | Default variables produce a valid plan with all default tags | done |
| U-02 | Unit | Invalid `name_prefix` is rejected | done |
| U-03 | Unit | Custom `tags` are merged with the default tags | done |
| U-04 | Unit | Instances get no public IP and run only in the private subnets | done |
| U-05 | Unit | IMDSv2 is enforced and EBS volumes are encrypted | done |
| U-06 | Unit | Instances accept traffic only from the load balancer security group | done |
| U-07 | Unit | Load balancer drops invalid headers, has access logs and runs in the public subnets | done |
| U-08 | Unit | With a certificate: HTTP redirects to HTTPS, TLS 1.2+ policy, HTTPS URL | done |
| U-09 | Unit | Log bucket blocks public access and is encrypted | done |
| U-10 | Unit | VPC flow logs capture all traffic | done |
| U-11 | Unit | `min_size` above `max_size` is rejected | done |
| I-01 | Integration | Apply waits until the instances are healthy in the target group, desired capacity is reached | done |
| I-02 | Integration | HTTP GET on the load balancer returns 200 and the demo page | done |

Integration tests are written but have not run against a real cloud account yet.
