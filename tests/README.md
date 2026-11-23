# Tests

Tests use the built-in OpenTofu test framework (`tofu test`, OpenTofu 1.9 or later).

| Level | Folder | What it does | Cost | When it runs |
|---|---|---|---|---|
| Unit | `tests/unit` | Plan only with mocked providers. Checks configuration and security settings. | None | Merge requests into `development` or `main`, and tags |
| Integration | `tests/integration` | Deploys real resources, checks them, destroys them. | Cloud cost while running | Tags, when cloud credentials are set (`integration-tests` job) |

In the GitLab pipeline, the `unit-tests` job also publishes the results as a JUnit test report (**Tests** tab of the pipeline and of the merge request). The script `ci/tofu-json-to-junit.py` converts the output of `tofu test -json` to JUnit XML.

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
| U-03 | Unit | Custom `advanced_settings.tags` are merged with the default tags | done |
| U-04 | Unit | Instances get no public IP and run only in the private subnets | done |
| U-05 | Unit | IMDSv2 is enforced and EBS volumes are encrypted | done |
| U-06 | Unit | Instances accept traffic only from the load balancer security group | done |
| U-07 | Unit | Load balancer drops invalid headers, has access logs and runs in the public subnets | done |
| U-08 | Unit | With a certificate: HTTP redirects to HTTPS, TLS 1.2+ policy, HTTPS URL | done |
| U-09 | Unit | Log bucket blocks public access and is encrypted | done |
| U-10 | Unit | VPC flow logs capture all traffic | done |
| U-11 | Unit | `advanced_settings.min_size` above `advanced_settings.max_size` is rejected | done |
| U-12 | Unit | `advanced_settings.min_size` above 10 and `max_size` above 20 are rejected | done |
| U-13 | Unit | The log bucket policy uses the log delivery service principal (works in all regions), limited to this account's `AWSLogs` path | done |
| U-14 | Unit | An empty `advanced_settings.certificate_arn` creates no HTTPS listener | done |
| U-15 | Unit | The subnets are in the first two zones that offer the instance type, and an instance type offered in fewer than two zones is rejected | done |
| U-16 | Unit | A newer Amazon Linux AMI does not change the launch template (no rolling replacement on a later run) | done |
| U-17 | Unit | The flow log role can only be assumed for flow logs of this account | done |
| I-01 | Integration | Apply waits until the instances are healthy in the target group, desired capacity is reached | done |
| I-02 | Integration | HTTP GET on the load balancer returns 200 and the demo page | done |

Integration tests are written but have not run against a real cloud account yet.
