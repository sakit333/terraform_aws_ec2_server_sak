#!/bin/bash
# ==========================================================
# 🧑‍💻 Author : Akshay Kumar (@sak_shetty)
# 🛠️  Role   : DevOps Engineer
# 🗓️  Purpose: Install & configure Grafana OSS (latest stable)
# ==========================================================

set -e

# ---------- COLORS ----------
GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RED="\e[31m"; BOLD="\e[1m"; RESET="\e[0m"

# ---------- HEADER ----------
clear
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}🧑‍💻 Author :${RESET} Akshay Kumar (@sak_shetty)"
echo -e "${BOLD}${GREEN}🛠️ Role   :${RESET} DevOps Engineer"
echo -e "${BOLD}${GREEN}🗓️ Purpose:${RESET} Install & configure Grafana OSS"
echo -e "${CYAN}==========================================================${RESET}\n"

# ---------- SYSTEM UPDATE ----------
echo -e "${YELLOW}🌀 Updating system packages...${RESET}"
sudo apt update -y > /dev/null
echo -e "${GREEN}✅ System updated successfully.${RESET}\n"

# ---------- INSTALL DEPENDENCIES ----------
echo -e "${YELLOW}📦 Installing required packages (wget, apt-transport-https, software-properties-common)...${RESET}"
sudo apt install -y wget apt-transport-https software-properties-common gnupg2 > /dev/null
echo -e "${GREEN}✅ Dependencies installed.${RESET}\n"

# ---------- ADD GRAFANA REPOSITORY ----------
if ! grep -q "grafana" /etc/apt/sources.list.d/* 2>/dev/null; then
    echo -e "${YELLOW}➕ Adding Grafana APT repository...${RESET}"
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add - > /dev/null
    echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
    echo -e "${GREEN}✅ Grafana repository added.${RESET}\n"
else
    echo -e "${GREEN}ℹ️  Grafana repository already exists. Skipping.${RESET}\n"
fi

# ---------- INSTALL GRAFANA ----------
echo -e "${YELLOW}⬇️  Installing Grafana OSS...${RESET}"
sudo apt update -y > /dev/null
sudo apt install -y grafana > /dev/null
echo -e "${GREEN}✅ Grafana installed successfully.${RESET}\n"

# ---------- ENABLE & START SERVICE ----------
echo -e "${YELLOW}🚀 Starting and enabling Grafana service...${RESET}"
sudo systemctl daemon-reload
sudo systemctl enable grafana-server > /dev/null
sudo systemctl start grafana-server
sleep 3

STATUS=$(systemctl is-active grafana-server)
if [[ "$STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ Grafana is running successfully!${RESET}"
else
    echo -e "${RED}❌ Grafana failed to start.${RESET}"
    echo -e "${YELLOW}Check logs using:${RESET} sudo journalctl -u grafana-server -f"
    exit 1
fi

# ---------- FIREWALL RULE (OPTIONAL) ----------
if command -v ufw &>/dev/null; then
    echo -e "${YELLOW}🌐 Allowing Grafana port 3000 in UFW...${RESET}"
    sudo ufw allow 3000/tcp > /dev/null 2>&1 || true
    echo -e "${GREEN}✅ Port 3000 opened for Grafana.${RESET}\n"
fi

# ---------- DEFAULT CREDENTIALS ----------
echo -e "${CYAN}🔐 Default Grafana Login:${RESET}"
echo -e "   ${YELLOW}Username:${RESET} admin"
echo -e "   ${YELLOW}Password:${RESET} admin"
echo -e "   You will be prompted to change it on first login.\n"

# ---------- FOOTER ----------
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}🎯 Installation Completed Successfully!${RESET}"
echo -e "${BOLD}${GREEN}🌐 Access Grafana UI at:${RESET} ${YELLOW}http://<your-server-ip>:3000${RESET}\n"
echo -e "${BOLD}${GREEN}🧠 Manage Grafana Service:${RESET}"
echo -e "   ${YELLOW}sudo systemctl status grafana-server${RESET}"
echo -e "   ${YELLOW}sudo systemctl restart grafana-server${RESET}"
echo -e "   ${YELLOW}sudo journalctl -u grafana-server -f${RESET}\n"
echo -e "${BOLD}${CYAN}✨ Script executed successfully by:${RESET} ${GREEN}Akshay Kumar (@sak_shetty)${RESET}"
echo -e "${CYAN}==========================================================${RESET}\n"
