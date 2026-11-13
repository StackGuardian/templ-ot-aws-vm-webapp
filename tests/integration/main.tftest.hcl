# Integration tests: deploy real resources, check them, then destroy them.
# This costs money and needs cloud credentials.
# Run: tofu test -test-directory=tests/integration
# Test case catalog: tests/README.md

variables {
  name_prefix = "itest"
  advanced_settings = {
    tags = {
      Purpose = "integration-test"
    }
  }
}

# I-01: apply waits until min_size instances are healthy in the target group (wait_for_elb_capacity).
run "deploy" {
  command = apply

  assert {
    condition     = aws_autoscaling_group.web.desired_capacity == var.advanced_settings.min_size
    error_message = "The Auto Scaling group does not have the desired capacity."
  }
}

# I-02
run "web_app_is_served" {
  module {
    source = "./tests/integration/http-check"
  }

  variables {
    url = run.deploy.url
  }

  assert {
    condition     = output.status_code == 200 && strcontains(output.body, "demo-marker: vm-webapp-ok")
    error_message = "The load balancer did not return the demo page."
  }
}
