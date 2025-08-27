#!/bin/bash

set -euo pipefail

# === CONFIG ===
SERVER_DIR="/opt/minecraft-bedrock-server"
BACKUP_DIR="/opt/minecraft-bedrock-server/backups"
TMP_DIR="/opt/minecraft-bedrock-server/bedrock_tmp"
LOG_DIR="/opt/minecraft-bedrock-server/update_logs"
SERVICE_NAME="minecraft"
DATE=$(date +%F)
LOG_FILE="$LOG_DIR/update_$DATE.log"
PROTECTED_FILES=("start_server.sh" "stop_server.sh" "allowlist.json" "permissions.json" "server.properties")
# Add directories that need to be recursively copied
DIRECTORIES=("behavior_packs" "resource_packs" "definitions" "structures")

# === SETUP ===
mkdir -p "$BACKUP_DIR" "$TMP_DIR" "$LOG_DIR"

# Redirect all output to log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[*] Minecraft Bedrock Server Update - $DATE"
echo "-------------------------------------------"

# === FETCH LATEST DOWNLOAD URL ===
echo "[*] Detecting latest Bedrock server version..."

# Use the Minecraft API to get the download links
API_RESPONSE=$(curl -s -A "Mozilla/5.0 (X11; Linux x86_64)" "https://net-secondary.web.minecraft-services.net/api/v1.0/download/links")

# Extract the serverBedrockLinux download URL using jq
DOWNLOAD_URL=$(echo "$API_RESPONSE" | jq -r '.result.links[] | select(.downloadType=="serverBedrockLinux") | .downloadUrl')

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "[!] Failed to detect latest download URL from API. Exiting."
fi

echo "[*] Latest server package URL: $DOWNLOAD_URL"

# === DOWNLOAD SERVER ZIP ===
cd "$TMP_DIR"
echo "[*] Downloading latest server package..."
curl -sL -A "Mozilla/5.0 (X11; Linux x86_64)" -o bedrock-server.zip "$DOWNLOAD_URL"

# Extract version from the download URL since version.json no longer exists
LATEST_VERSION=$(echo "$DOWNLOAD_URL" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
echo "[*] Latest version (from URL): $LATEST_VERSION"

# === GET CURRENT VERSION ===
CURRENT_VERSION="unknown"
if [[ -f "$SERVER_DIR/version.json" ]]; then
    # Try the old method first (version.json)
    CURRENT_VERSION=$(jq -r .version "$SERVER_DIR/version.json" 2>/dev/null || echo "unknown")
    echo "[*] Currently installed version (from version.json): $CURRENT_VERSION"
else
    # Check if we have a stored version file
    if [[ -f "$SERVER_DIR/.version" ]]; then
        CURRENT_VERSION=$(cat "$SERVER_DIR/.version")
        echo "[*] Currently installed version (from .version): $CURRENT_VERSION"
    else
        echo "[*] No version information found — treating as fresh install."
    fi
fi

# === COMPARE VERSIONS ===
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "[✓] Server is already up-to-date (version $CURRENT_VERSION). No update needed."
    rm -rf "$TMP_DIR"
    exit 0
fi

echo "[!] Updating from version $CURRENT_VERSION to $LATEST_VERSION..."

# === STOP SERVER ===
echo "[*] Stopping Minecraft service..."
sudo systemctl stop "$SERVICE_NAME"

# === BACKUP CURRENT SERVER ===
echo "[*] Creating backup..."
tar -czf "$BACKUP_DIR/bedrock_backup_$DATE.tar.gz" -C "$SERVER_DIR" .

# === CLEAN OLD BACKUPS ===
echo "[*] Deleting backups older than 90 days..."
find "$BACKUP_DIR" -type f -name 'bedrock_backup_*.tar.gz' -mtime +90 -exec rm -v {} \;

# === UNZIP FULL PACKAGE ===
echo "[*] Extracting full server package..."
unzip -o bedrock-server.zip > /dev/null

# === UPDATE FILES (SKIP PROTECTED) ===
echo "[*] Updating server files (preserving protected files)..."
for file in *; do
    if [[ " ${PROTECTED_FILES[@]} " =~ " ${file} " ]]; then
        echo "[=] Skipping protected file: $file"
        continue
    fi

    if [[ -d "$file" ]]; then
        # Handle directories by copying recursively
        echo "[*] Copying directory: $file"
        cp -rv "$file" "$SERVER_DIR"
    else
        # Handle regular files
        cp -v "$file" "$SERVER_DIR"
        [[ "$file" == "bedrock_server" ]] && chmod +x "$SERVER_DIR/$file"
    fi
done

# Store the current version for future reference
echo "$LATEST_VERSION" > "$SERVER_DIR/.version"
echo "[*] Stored version information for future updates"

# === CLEAN TEMP ===
echo "[*] Cleaning temporary files..."
rm -rf "$TMP_DIR"

# === START SERVER ===
echo "[*] Starting Minecraft service..."
sudo systemctl start "$SERVICE_NAME"

echo "[✓] Minecraft Bedrock Server updated to version $LATEST_VERSION"