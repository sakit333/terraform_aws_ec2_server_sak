#!/bin/bash
# ==========================================================
# 🧑‍💻 Author : Akshay Kumar (alias @sak_shetty)
# 🛠️  Role   : DevOps Engineer
# 📜 Script  : install_prometheus.sh
# 🗓️  Purpose: Fully automated Prometheus installation & configuration
# ==========================================================

set -e

# ---------- COLORS ----------
GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; BOLD="\e[1m"; RESET="\e[0m"

echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}🧑‍💻 Author :${RESET} Akshay Kumar (@sak_shetty)"
echo -e "${BOLD}${GREEN}🛠️ Role   :${RESET} DevOps Engineer"
echo -e "${BOLD}${GREEN}🗓️ Purpose:${RESET} Install & configure Prometheus monitoring"
echo -e "${CYAN}==========================================================${RESET}\n"

# ---------- VARIABLES ----------
PROM_VERSION="2.54.1"  # (Latest LTS as of Oct 2025)
PROM_USER="prometheus"
INSTALL_DIR="/opt/prometheus"
CONFIG_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"
SERVICE_FILE="/etc/systemd/system/prometheus.service"
PROM_TAR="prometheus-${PROM_VERSION}.linux-amd64.tar.gz"
PROM_URL="https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/${PROM_TAR}"

# ---------- UPDATE SYSTEM ----------
echo -e "${YELLOW}🌀 Updating system packages...${RESET}"
sudo apt update -y && sudo apt install -y wget tar

# ---------- CREATE USER ----------
if id "$PROM_USER" &>/dev/null; then
    echo -e "${GREEN}ℹ️ User '${PROM_USER}' already exists.${RESET}"
else
    sudo useradd --no-create-home --shell /bin/false ${PROM_USER}
    echo -e "${GREEN}✅ Created prometheus user.${RESET}"
fi

# ---------- CREATE DIRECTORIES ----------
echo -e "${YELLOW}📁 Creating directories...${RESET}"
sudo mkdir -p ${CONFIG_DIR} ${DATA_DIR} ${INSTALL_DIR}
sudo chown -R ${PROM_USER}:${PROM_USER} ${CONFIG_DIR} ${DATA_DIR}
sudo chmod -R 755 ${CONFIG_DIR} ${DATA_DIR}
echo -e "${GREEN}✅ Directory structure prepared.${RESET}"

# ---------- DOWNLOAD & EXTRACT PROMETHEUS ----------
if [ ! -f "${INSTALL_DIR}/prometheus" ]; then
    echo -e "${YELLOW}⬇️ Downloading Prometheus ${PROM_VERSION}...${RESET}"
    cd /tmp
    wget -q ${PROM_URL}
    tar -xzf ${PROM_TAR}
    cd prometheus-${PROM_VERSION}.linux-amd64
    sudo cp prometheus promtool /usr/local/bin/
    sudo mkdir -p ${INSTALL_DIR}
    sudo cp -r consoles console_libraries ${INSTALL_DIR}/
    echo -e "${GREEN}✅ Prometheus binaries installed.${RESET}"
else
    echo -e "${GREEN}ℹ️ Prometheus already installed, skipping download.${RESET}"
fi

# ---------- CONFIGURE prometheus.yml ----------
echo -e "${YELLOW}⚙️ Creating Prometheus configuration...${RESET}"
sudo tee ${CONFIG_DIR}/prometheus.yml >/dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

sudo chown -R ${PROM_USER}:${PROM_USER} ${CONFIG_DIR}
echo -e "${GREEN}✅ Configuration file created at ${CONFIG_DIR}/prometheus.yml.${RESET}"

# ---------- CREATE SYSTEMD SERVICE ----------
if [ ! -f "${SERVICE_FILE}" ]; then
    echo -e "${YELLOW}🧩 Creating systemd service for Prometheus...${RESET}"
    sudo tee ${SERVICE_FILE} >/dev/null <<EOF
[Unit]
Description=Prometheus Monitoring System
After=network-online.target

[Service]
User=${PROM_USER}
Group=${PROM_USER}
Type=simple
ExecStart=/usr/local/bin/prometheus \\
    --config.file=${CONFIG_DIR}/prometheus.yml \\
    --storage.tsdb.path=${DATA_DIR} \\
    --web.console.templates=${INSTALL_DIR}/consoles \\
    --web.console.libraries=${INSTALL_DIR}/console_libraries

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${GREEN}✅ Systemd service created at ${SERVICE_FILE}.${RESET}"
else
    echo -e "${GREEN}ℹ️ Service file already exists, skipping.${RESET}"
fi

# ---------- ENABLE & START SERVICE ----------
echo -e "${YELLOW}🚀 Starting Prometheus service...${RESET}"
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus

sleep 5

# ---------- VERIFY SERVICE ----------
if systemctl is-active --quiet prometheus; then
    echo -e "${GREEN}✅ Prometheus is running successfully.${RESET}"
else
    echo -e "${RED}❌ Prometheus failed to start. Check logs using:${RESET}"
    echo -e "${YELLOW}sudo journalctl -u prometheus -f${RESET}"
    exit 1
fi

# ---------- INFO ----------
echo ""
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}🌐 Access Prometheus UI at:${RESET} ${YELLOW}http://<your-server-ip>:9090${RESET}"
echo -e "${BOLD}${GREEN}📁 Config file:${RESET} ${CONFIG_DIR}/prometheus.yml"
echo -e "${BOLD}${GREEN}📦 Data directory:${RESET} ${DATA_DIR}"
echo -e "${BOLD}${GREEN}🧠 Manage service with:${RESET}"
echo -e "   ${YELLOW}sudo systemctl start prometheus${RESET}"
echo -e "   ${YELLOW}sudo systemctl stop prometheus${RESET}"
echo -e "   ${YELLOW}sudo systemctl restart prometheus${RESET}"
echo -e "   ${YELLOW}sudo systemctl status prometheus${RESET}"
echo -e "${CYAN}==========================================================${RESET}"

# ---------- FOOTER ----------
echo ""
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}✅Install & configure Prometheus monitoring completed!${RESET}"
echo -e "${MAGENTA}👨‍💻 Executed by Akshay Kumar (@sak_shetty)${RESET}"
echo -e "${BLUE}🕒 Execution Time:${RESET} $(date)"
echo -e "${CYAN}==========================================================${RESET}"
echo ""
