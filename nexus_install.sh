#!/bin/bash
# ==========================================================
# 🧑‍💻 Author : Akshay Kumar (@sak_shetty)
# 🛠️  Role   : DevOps Engineer
# 🗓️  Purpose: Fully automated Nexus OSS installation & configuration (v3.85.0-03)
# ==========================================================

set -e

# ---------- COLORS ----------
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"
MAGENTA="\e[35m"; CYAN="\e[36m"; BOLD="\e[1m"; RESET="\e[0m"

# ---------- HEADER ----------
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}🧑‍💻 Author :${RESET} Akshay Kumar (alias @sak_shetty)"
echo -e "${BOLD}${GREEN}🛠️  Role   :${RESET} DevOps Engineer"
echo -e "${BOLD}${GREEN}🗓️  Purpose:${RESET} Install & configure Nexus Repository OSS"
echo -e "${CYAN}==========================================================${RESET}\n"

# ---------- VARIABLES ----------
NEXUS_VERSION="3.85.0-03"
NEXUS_USER="nexus"
INSTALL_DIR="/opt"
NEXUS_DIR="${INSTALL_DIR}/nexus"
DATA_DIR="${INSTALL_DIR}/sonatype-work"
SERVICE_FILE="/etc/systemd/system/nexus.service"
NEXUS_TAR="nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"
NEXUS_URL="https://download.sonatype.com/nexus/3/${NEXUS_TAR}"

# Detect JAVA_HOME
JAVA_HOME_PATH=$(readlink -f /usr/bin/java | sed "s:bin/java::")

# ---------- CHECK JAVA ----------
echo -e "${YELLOW}☕ Checking for Java 17...${RESET}"
if java -version 2>&1 | grep -q '17'; then
    echo -e "${GREEN}✅ Java 17 is already installed.${RESET}"
else
    echo -e "${YELLOW}⚙️ Installing OpenJDK 17 JRE (headless)...${RESET}"
    sudo apt update -y
    sudo apt install -y openjdk-17-jre-headless wget tar
    JAVA_HOME_PATH=$(readlink -f /usr/bin/java | sed "s:bin/java::")
fi

# ---------- CREATE NEXUS USER ----------
if id "$NEXUS_USER" &>/dev/null; then
    echo -e "${GREEN}ℹ️ User '${NEXUS_USER}' already exists.${RESET}"
else
    sudo useradd -r -m -s /bin/bash ${NEXUS_USER}
    echo -e "${GREEN}✅ Created user '${NEXUS_USER}'.${RESET}"
fi

# ---------- PASSWORDLESS SUDO FOR NEXUS ----------
if ! sudo grep -q "^${NEXUS_USER} " /etc/sudoers.d/nexus_sudo 2>/dev/null; then
    echo "${NEXUS_USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/nexus_sudo
    sudo chmod 440 /etc/sudoers.d/nexus_sudo
    echo -e "${GREEN}✅ Nexus user given passwordless sudo.${RESET}"
else
    echo -e "${GREEN}ℹ️ Nexus user already has sudo privileges. Skipping.${RESET}"
fi

# ---------- CREATE DIRECTORIES ----------
sudo mkdir -p ${NEXUS_DIR} ${DATA_DIR}/nexus3
sudo chown -R ${NEXUS_USER}:${NEXUS_USER} ${NEXUS_DIR} ${DATA_DIR}
sudo chmod -R 755 ${NEXUS_DIR} ${DATA_DIR}
echo -e "${GREEN}✅ Directories ensured and permissions set.${RESET}"

# ---------- DOWNLOAD & EXTRACT NEXUS ----------
if [ ! -f "${NEXUS_DIR}/bin/nexus" ]; then
    echo -e "${YELLOW}⬇️ Nexus not found, downloading...${RESET}"
    cd /tmp
    wget -q $NEXUS_URL
    sudo rm -rf ${NEXUS_DIR}
    sudo tar -xzf ${NEXUS_TAR} -C ${INSTALL_DIR}
    sudo mv ${INSTALL_DIR}/nexus-${NEXUS_VERSION} ${NEXUS_DIR}
    sudo chown -R ${NEXUS_USER}:${NEXUS_USER} ${NEXUS_DIR}
    echo -e "${GREEN}✅ Nexus extracted to ${NEXUS_DIR}.${RESET}"
else
    echo -e "${GREEN}ℹ️ Nexus already exists and bin/nexus is present. Skipping download.${RESET}"
fi

# ---------- CLEAN OLD PID FILES ----------
sudo rm -f ${NEXUS_DIR}/nexus3.pid
sudo rm -f ${DATA_DIR}/nexus3/nexus3.pid
sudo pkill -f nexus || true
echo -e "${GREEN}✅ Old Nexus processes and PID files cleaned.${RESET}"

# ---------- CONFIGURE nexus.rc ----------
echo -e "${YELLOW}⚙️ Configuring nexus.rc...${RESET}"
sudo tee ${NEXUS_DIR}/bin/nexus.rc >/dev/null <<EOF
run_as_user=${NEXUS_USER}
EOF
sudo chmod 644 ${NEXUS_DIR}/bin/nexus.rc
echo -e "${GREEN}✅ nexus.rc configured with run_as_user.${RESET}"

# ---------- CREATE SYSTEMD SERVICE ----------
if [ ! -f "${SERVICE_FILE}" ]; then
    echo -e "${YELLOW}🧩 Creating systemd service...${RESET}"
    sudo tee ${SERVICE_FILE} >/dev/null <<EOF
[Unit]
Description=Sonatype Nexus Repository
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=${NEXUS_USER}
Group=${NEXUS_USER}
ExecStart=${NEXUS_DIR}/bin/nexus start
ExecStop=${NEXUS_DIR}/bin/nexus stop
Restart=on-failure
TimeoutSec=600
WorkingDirectory=${NEXUS_DIR}
Environment=INSTALL4J_JAVA_HOME_OVERRIDE=${JAVA_HOME_PATH}

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${GREEN}✅ Nexus service created at ${SERVICE_FILE}.${RESET}"
else
    echo -e "${GREEN}ℹ️ Service file already exists. Skipping.${RESET}"
fi

# ---------- EXPORT JAVA_HOME FOR NEXUS USER ----------
sudo -u ${NEXUS_USER} bash -c "echo 'export JAVA_HOME=${JAVA_HOME_PATH}' >> ~/.bashrc"

# ---------- ENSURE SONATYPE-WORK DIRECTORY OWNERSHIP ----------
sudo mkdir -p ${DATA_DIR}/nexus3
sudo chown -R ${NEXUS_USER}:${NEXUS_USER} ${DATA_DIR}
sudo chmod -R 755 ${DATA_DIR}

# ---------- START NEXUS SERVICE ----------
echo -e "${YELLOW}🚀 Starting Nexus service...${RESET}"
sudo systemctl daemon-reload
sudo systemctl enable nexus >/dev/null 2>&1 || true
sudo systemctl restart nexus || sudo systemctl start nexus

# Wait a few seconds to let Nexus start
sleep 10

# ---------- CHECK LOG FILE ----------
LOG_FILE="${DATA_DIR}/nexus3/log/nexus.log"
if [ -f "$LOG_FILE" ]; then
    echo -e "${GREEN}✅ Nexus service log file exists.${RESET}"
else
    echo -e "${RED}❌ Nexus log file not found. Check manually.${RESET}"
fi

# ---------- INFO ----------
echo -e "${GREEN}🌐 Access Nexus at:${RESET} ${BLUE}http://<your-server-ip>:8081${RESET}"
if [ -f "${DATA_DIR}/nexus3/admin.password" ]; then
    echo -e "${YELLOW}🗝️ Default admin password:${RESET}"
    sudo cat ${DATA_DIR}/nexus3/admin.password
else
    echo -e "${MAGENTA}🕒 Admin password will appear after first full startup.${RESET}"
fi

# ---------- FOOTER ----------
echo ""
echo -e "${BOLD}${YELLOW}💡 Manage Nexus using:${RESET}"
echo -e "   ${GREEN}sudo systemctl start nexus${RESET}"
echo -e "   ${GREEN}sudo systemctl stop nexus${RESET}"
echo -e "   ${GREEN}sudo systemctl restart nexus${RESET}"
echo -e "   ${GREEN}sudo systemctl status nexus${RESET}"
echo ""
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}✅ Nexus installation and configuration completed!${RESET}"
echo -e "${MAGENTA}👨‍💻 Executed by Akshay Kumar (@sak_shetty)${RESET}"
echo -e "${BLUE}🕒 Execution Time:${RESET} $(date)"
echo -e "${CYAN}==========================================================${RESET}"
echo ""
