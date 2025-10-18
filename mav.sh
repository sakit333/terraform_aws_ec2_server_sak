#!/bin/bash
# Apache Maven Installer Script
# scripted by @sak_shetty — DevOps Engineer

# ─────────────────────────────────────────
# Constants and Colors
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
BOLD="\e[1m"
RESET="\e[0m"

# ────────────────────────────────────────────────────────────────────
# Professional Header
clear
echo -e "${CYAN}${BOLD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                 Apache Maven Installer  v3.9.11"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}     scripted by sak_shetty — DevOps Engineer${RESET}"
echo

# ────────────────────────────────────────────────────────────────────
# Variables
MAVEN_VERSION="3.9.11"
MAVEN_ARCHIVE="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
MAVEN_FOLDER="apache-maven-${MAVEN_VERSION}"
INSTALL_PATH="$HOME/maven"
BASHRC="$HOME/.bashrc"
EXPORT_LINE='export PATH=$HOME/maven/bin:$PATH'

# ────────────────────────────────────────────────────────────────────
# Step 1: Download
echo -e "${BOLD}→ Downloading Maven ${MAVEN_VERSION}...${RESET}"
wget -q --show-progress "https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_ARCHIVE}"
if [ $? -ne 0 ]; then
  echo -e "${RED}✘ Download failed. Please check your internet connection.${RESET}"
  exit 1
fi

# ────────────────────────────────────────────────────────────────────
# Step 2: Extract
echo -e "${BOLD}→ Extracting archive...${RESET}"
tar -zxf "$MAVEN_ARCHIVE"
if [ $? -ne 0 ]; then
  echo -e "${RED}✘ Failed to extract archive.${RESET}"
  rm -f "$MAVEN_ARCHIVE"
  exit 1
fi
rm -f "$MAVEN_ARCHIVE"

# ────────────────────────────────────────────────────────────────────
# Step 3: Move to target directory
echo -e "${BOLD}→ Installing Maven to $INSTALL_PATH...${RESET}"
if [ -d "$INSTALL_PATH" ]; then
  echo -e "${YELLOW}• Removing existing Maven directory...${RESET}"
  rm -rf "$INSTALL_PATH"
fi
mv "$MAVEN_FOLDER" "$INSTALL_PATH"

# ────────────────────────────────────────────────────────────────────
# Step 4: Update PATH
echo -e "${BOLD}→ Configuring environment...${RESET}"
if ! grep -Fq "$EXPORT_LINE" "$BASHRC"; then
  echo "$EXPORT_LINE" >> "$BASHRC"
  echo -e "${GREEN}• Added Maven path to $BASHRC${RESET}"
else
  echo -e "${YELLOW}• Maven path already present in $BASHRC${RESET}"
fi

# Temporary PATH update for current shell
export PATH="$HOME/maven/bin:$PATH"

# ────────────────────────────────────────────────────────────────────
# Step 5: Verify Installation
echo
echo -e "${BOLD}→ Verifying Maven installation...${RESET}"
if mvn --version >/dev/null 2>&1; then
  echo -e "${GREEN}✔ Maven installed successfully.${RESET}"
  echo
  mvn --version
else
  echo -e "${RED}✘ Maven not available in current shell.${RESET}"
  echo -e "${YELLOW}• Run: source ~/.bashrc${RESET} to activate it or open a new terminal."
fi

# ─────────────────────────────────────────
# Reminder
echo
echo -e "${BOLD}After installation is complete, run the following:${RESET}"
echo -e "${CYAN}[INFO] Command: source .bashrc${RESET}"
echo -e "${CYAN}[CHECK] Check Maven version: mvn --version${RESET}"

# ────────────────────────────────────────────────────────────────────
# Done
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}Installation completed — scripted by @sak_shetty${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
