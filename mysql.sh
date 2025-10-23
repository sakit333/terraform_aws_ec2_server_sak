#!/bin/bash
# setup_mysql.sh
# Automate MySQL installation, configuration, and remote access setup

# Exit on error
set -e

# Variables
MYSQL_ROOT_PASSWORD="1234"
MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"

echo "🚀 Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing MySQL server..."
sudo apt install -y mysql-server

echo "✅ Checking MySQL version..."
sudo mysql --version

echo "🔧 Configuring MySQL root password and remote access..."

# Run SQL commands directly from shell
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "🌐 Enabling remote connections..."

# Backup config before modifying
if [ -f "$MYSQL_CONF" ]; then
  sudo cp "$MYSQL_CONF" "${MYSQL_CONF}.bak"
  echo "✅ Backup created at ${MYSQL_CONF}.bak"
fi

# Update bind-address to allow remote connections
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" "$MYSQL_CONF"

echo "🔁 Restarting MySQL service..."
sudo systemctl restart mysql

echo "🟢 Checking MySQL service status..."
sudo systemctl status mysql --no-pager

echo "🎉 MySQL installation and configuration complete!"
echo "✅ Root password: ${MYSQL_ROOT_PASSWORD}"
echo "✅ Remote access enabled (bind-address = 0.0.0.0)"
