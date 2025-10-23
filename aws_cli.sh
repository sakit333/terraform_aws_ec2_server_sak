#!/bin/bash
# ==========================================================
# 🧑‍💻 Author : Akshay Kumar (alias @sak_shetty)
# 🛠️  Role   : DevOps Engineer
# 🗓️  Purpose: Automate installation of AWS CLI v2 on Ubuntu with styled output.
# ==========================================================

# Exit immediately on error
set -e

# ---------- COLORS ----------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# ---------- HEADER ----------
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}🧑‍💻 Author :${RESET} Akshay Kumar (alias @sak_shetty)"
echo -e "${BOLD}${GREEN}🛠️  Role   :${RESET} DevOps Engineer"
echo -e "${BOLD}${GREEN}🗓️  Purpose:${RESET} Automate installation of AWS CLI v2 on Ubuntu"
echo -e "${CYAN}==========================================================${RESET}\n"

# ---------- MAIN SCRIPT ----------

# 1. Update packages
echo -e "${YELLOW}🚀 Updating system packages...${RESET}"
sudo apt update -y

# 2. Install required packages
echo -e "${YELLOW}📦 Installing required dependencies (unzip, curl)...${RESET}"
sudo apt install -y unzip curl

# 3. Download AWS CLI v2 installer
echo -e "${YELLOW}⬇️  Downloading AWS CLI v2 installer...${RESET}"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# 4. Unzip the installer
echo -e "${YELLOW}📂 Extracting AWS CLI installer...${RESET}"
unzip -o awscliv2.zip

# 5. Run the installer
echo -e "${YELLOW}⚙️  Installing AWS CLI v2...${RESET}"
sudo ./aws/install

# 6. Check the version
echo -e "${GREEN}✅ Verifying AWS CLI installation...${RESET}"
aws --version

# Cleanup (optional)
echo -e "${YELLOW}🧹 Cleaning up installation files...${RESET}"
rm -rf aws awscliv2.zip

# ---------- FOOTER ----------
echo ""
echo -e "${CYAN}==========================================================${RESET}"
echo -e "${BOLD}${GREEN}✅ AWS CLI v2 installation completed successfully!${RESET}"
echo -e "${MAGENTA}👨‍💻 Executed by Akshay Kumar (@sak_shetty)${RESET}"
echo -e "${BLUE}🕒 Execution Time:${RESET} $(date)"
echo -e "${CYAN}==========================================================${RESET}"
