#!/bin/bash
set -eux

apt-get update -y
apt-get install -y apache2
systemctl enable --now apache2

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html>
  <head><title>Terraform Web Server</title></head>
  <body>
    <h1>Welcome to ${project_name}</h1>
    <p>Environment: ${environment}</p>
    <p>Server: $(hostname)</p>
  </body>
</html>
EOF
