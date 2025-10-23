#!/bin/bash
# ==========================================================
# 🧑‍💻 Author : Akshay Kumar (@sak_shetty)
# 🛠️  Role   : DevOps Engineer
# 📜 Script  : install_node_exporter.sh
# 🗓️  Purpose: Install & configure Prometheus Node Exporter
# ==========================================================

set -e

# ---------- COLORS ----------
GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RED="\e[31m"; BOLD="\e[1m"; RESET="\e[0m"

# ---------- HEADER ----------
clear
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}🧑‍💻 Author :${RESET} Akshay Kumar (@sak_shetty)"
echo -e "${BOLD}${GREEN}🛠️  Role   :${RESET} DevOps Engineer"
echo -e "${BOLD}${GREEN}🗓️  Purpose:${RESET} Install & configure Prometheus Node Exporter"
echo -e "${CYAN}==========================================================${RESET}\n"

# ---------- VARIABLES ----------
NODE_VERSION="1.8.2"
NODE_USER="node_exporter"
NODE_SERVICE="/etc/systemd/system/node_exporter.service"
NODE_TAR="node_exporter-${NODE_VERSION}.linux-amd64.tar.gz"
NODE_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/${NODE_TAR}"

# ---------- UPDATE SYSTEM ----------
echo -e "${YELLOW}🌀 Updating system packages...${RESET}"
sudo apt update -y && sudo apt install -y wget tar > /dev/null
echo -e "${GREEN}✅ System packages updated.${RESET}\n"

# ---------- CREATE USER ----------
if id "$NODE_USER" &>/dev/null; then
    echo -e "${GREEN}ℹ️  User '${NODE_USER}' already exists.${RESET}"
else
    sudo useradd --no-create-home --shell /bin/false ${NODE_USER}
    echo -e "${GREEN}✅ Created user '${NODE_USER}'.${RESET}"
fi

# ---------- DOWNLOAD & INSTALL ----------
if [ ! -f "/usr/local/bin/node_exporter" ]; then
    echo -e "${YELLOW}⬇️  Downloading Node Exporter v${NODE_VERSION}...${RESET}"
    cd /tmp
    wget -q ${NODE_URL}
    tar -xzf ${NODE_TAR}
    cd node_exporter-${NODE_VERSION}.linux-amd64
    sudo cp node_exporter /usr/local/bin/
    sudo chown ${NODE_USER}:${NODE_USER} /usr/local/bin/node_exporter
    echo -e "${GREEN}✅ Node Exporter installed successfully.${RESET}\n"
else
    echo -e "${GREEN}ℹ️  Node Exporter already installed, skipping download.${RESET}\n"
fi

# ---------- CREATE SYSTEMD SERVICE ----------
if [ ! -f "${NODE_SERVICE}" ]; then
    echo -e "${YELLOW}🧩 Creating Node Exporter systemd service...${RESET}"
    sudo tee ${NODE_SERVICE} >/dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=${NODE_USER}
Group=${NODE_USER}
Type=simple
ExecStart=/usr/local/bin/node_exporter

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${GREEN}✅ Node Exporter service created at ${NODE_SERVICE}.${RESET}\n"
else
    echo -e "${GREEN}ℹ️  Node Exporter service already exists. Skipping creation.${RESET}\n"
fi

# ---------- ENABLE & START SERVICE ----------
echo -e "${YELLOW}🚀 Starting Node Exporter service...${RESET}"
sudo systemctl daemon-reload
sudo systemctl enable node_exporter > /dev/null
sudo systemctl restart node_exporter

sleep 3

# ---------- VERIFY ----------
STATUS=$(systemctl is-active node_exporter)
if [[ "$STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ Node Exporter is running successfully!${RESET}"
else
    echo -e "${RED}❌ Node Exporter failed to start.${RESET}"
    echo -e "${YELLOW}Check logs with:${RESET} sudo journalctl -u node_exporter -f"
    exit 1
fi

# ---------- FOOTER ----------
echo -e "\n${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}🎯 Installation Completed Successfully!${RESET}"
echo -e "${BOLD}${GREEN}🌐 Access Metrics at:${RESET} ${YELLOW}http://<your-server-ip>:9100/metrics${RESET}\n"
echo -e "${BOLD}${GREEN}🧠 Manage Node Exporter:${RESET}"
echo -e "   ${YELLOW}sudo systemctl status node_exporter${RESET}"
echo -e "   ${YELLOW}sudo systemctl restart node_exporter${RESET}"
echo -e "   ${YELLOW}sudo journalctl -u node_exporter -f${RESET}"
echo -e "\n${BOLD}${CYAN}✨ Script executed successfully by:${RESET} ${GREEN}Akshay Kumar (@sak_shetty)${RESET}"
echo -e "${CYAN}==========================================================${RESET}\n"
