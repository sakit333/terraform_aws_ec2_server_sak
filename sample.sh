#!/bin/bash
# Update and install nginx
sudo apt update -y
sudo apt install -y nginx

# Create custom HTML content
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Welcome to Dev Environment</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f4;
      text-align: center;
      padding: 50px;
    }
    h1 {
      color: #333;
    }
    footer {
      margin-top: 40px;
      font-size: 14px;
      color: #777;
    }
  </style>
</head>
<body>
  <h1>Hello from Terraform EC2 with NGINX!</h1>
  <p>This environment was scripted by <strong>sak_shetty</strong> for students' DevOps practice.</p>
  <footer>
    &copy; 2025 sak_shetty. All rights reserved.
  </footer>
</body>
</html>
EOF

# Ensure nginx is running
sudo systemctl enable nginx
sudo systemctl restart nginx
