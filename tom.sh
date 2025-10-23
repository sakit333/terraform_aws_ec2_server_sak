#!/usr/bin/env bash
# simple_tomcat_fix.sh
# Usage: sudo ./simple_tomcat_fix.sh [TOMCAT_DIR]
set -euo pipefail

TOMCAT_DIR="${1:-./apache-tomcat-9.0.111}"
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="/root/tomcat-backups/$TS"
mkdir -p "$BACKUP_DIR"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo). Exiting."
  exit 1
fi

# 1) Check Java 17
if ! command -v java >/dev/null 2>&1; then
  echo "ERROR: java not found. Install Java 17 and re-run. Exiting."
  exit 2
fi
JAVA_V="$(java -version 2>&1 | tr '\n' ' ')"
if ! echo "$JAVA_V" | grep -qE '(^| )[0-9]*"?17|openjdk version "17'; then
  echo "ERROR: Java 17 not detected. Found: $JAVA_V"
  echo "Install Java 17 and re-run. Exiting."
  exit 3
fi
echo "Java 17 detected: $JAVA_V"

# Files
USERS_FILE="${TOMCAT_DIR}/conf/tomcat-users.xml"
CONTEXT_FILE="${TOMCAT_DIR}/webapps/manager/META-INF/context.xml"

# sanity checks
if [[ ! -f "$USERS_FILE" ]]; then
  echo "ERROR: tomcat-users.xml not found at $USERS_FILE. Exiting."
  exit 4
fi

# backup helper
backup() {
  local f="$1"
  if [[ -f "$f" ]]; then
    mkdir -p "$BACKUP_DIR$(dirname "$f")"
    cp -a "$f" "$BACKUP_DIR$(dirname "$f")/"
    echo "Backed up $f -> $BACKUP_DIR$(dirname "$f")/"
  fi
}

# 2) Ensure roles + admin user (idempotent)
backup "$USERS_FILE"
if grep -q 'rolename="manager-gui"' "$USERS_FILE" && grep -q 'username="admin"' "$USERS_FILE"; then
  echo "tomcat-users.xml already has manager roles and admin user. Skipping."
else
  echo "Adding manager roles and admin user to $USERS_FILE"
  # append just before closing tag
  awk '
  /<\/tomcat-users>/ && !added {
    print "  <role rolename=\"manager-gui\"/>"
    print "  <role rolename=\"manager-script\"/>"
    print "  <role rolename=\"manager-jmx\"/>"
    print "  <role rolename=\"manager-status\"/>"
    print "  <user username=\"admin\" password=\"admin\" roles=\"manager-gui, manager-script, manager-jmx, manager-status\"/>"
    added=1
  }
  { print }
  ' "$USERS_FILE" > "${USERS_FILE}.tmp" && mv "${USERS_FILE}.tmp" "$USERS_FILE"
  echo "Inserted roles/user into $USERS_FILE"
fi

# 3) Comment CookieProcessor...Valve block in context.xml (idempotent)
if [[ ! -f "$CONTEXT_FILE" ]]; then
  echo "Warning: context.xml not found at $CONTEXT_FILE. Skipping context change."
else
  backup "$CONTEXT_FILE"
  # If CookieProcessor already inside <!-- --> skip
  if grep -qE "<!--.*CookieProcessor|CookieProcessor.*-->" "$CONTEXT_FILE"; then
    echo "context.xml already contains commented CookieProcessor or it is inside a comment. Skipping."
  else
    # Check presence of start and end lines
    if grep -q 'CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"' "$CONTEXT_FILE" && \
       grep -q 'Valve className="org.apache.catalina.valves.RemoteCIDRValve"' "$CONTEXT_FILE"; then
      echo "Commenting CookieProcessor -> RemoteCIDRValve block in $CONTEXT_FILE"
      awk '
      BEGIN{inblock=0}
      {
        if(inblock==0 && $0 ~ /CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"/){
          print "<!--"
          inblock=1
        }
        print
        if(inblock==1 && $0 ~ /Valve className="org.apache.catalina.valves.RemoteCIDRValve"/){
          print "-->"
          inblock=0
        }
      }
      ' "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp" && mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"
      echo "context.xml updated."
    else
      echo "Could not find both CookieProcessor and RemoteCIDRValve lines in $CONTEXT_FILE. No change made."
    fi
  fi
fi

# 4) Start Tomcat
STARTUP="${TOMCAT_DIR}/bin/startup.sh"
if [[ -x "$STARTUP" ]]; then
  echo "Starting Tomcat..."
  "$STARTUP" || echo "Tomcat startup script returned non-zero; check logs."
  sleep 1
  if [[ -f "${TOMCAT_DIR}/logs/catalina.out" ]]; then
    echo "---- tail -n 20 catalina.out ----"
    tail -n 20 "${TOMCAT_DIR}/logs/catalina.out"
    echo "---------------------------------"
  fi
else
  echo "Startup script not found or not executable: $STARTUP. Skipping start."
fi

echo "Done. Backups are in $BACKUP_DIR"
