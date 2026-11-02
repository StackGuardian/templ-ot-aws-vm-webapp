#!/bin/bash
# Installs nginx and writes a demo page that shows which instance answered.
set -euo pipefail

dnf install -y nginx

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

cat > /usr/share/nginx/html/index.html <<HTML
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Web app demo</title></head>
<body>
  <h1>Web app demo</h1>
  <p>Served by instance ${INSTANCE_ID}.</p>
  <!-- demo-marker: vm-webapp-ok -->
</body>
</html>
HTML

# Hide the nginx version in headers and error pages.
sed -i 's/http {/http {\n    server_tokens off;/' /etc/nginx/nginx.conf

systemctl enable --now nginx
