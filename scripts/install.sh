#!/bin/zsh
# install.sh - Installs and configures the Minecraft Bedrock server as a service
# Usage: sudo ./install.sh


set -e

# Ensure minecraft user and group exist
if ! id -u minecraft >/dev/null 2>&1; then
	sudo useradd -r -m -d /opt/minecraft-bedrock-server -s /usr/sbin/nologin minecraft
	echo "Created user 'minecraft'"
fi

# Variables
INSTALL_DIR="/opt/minecraft-bedrock-server"
SERVICE_FILE="/etc/systemd/system/minecraft.service"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"


# 1. Create install directory
sudo mkdir -p "$INSTALL_DIR"
sudo chown minecraft:minecraft "$INSTALL_DIR"


# 2. Copy server scripts
sudo cp "$SCRIPT_DIR/start_server.sh" "$INSTALL_DIR/start_server.sh"
sudo cp "$SCRIPT_DIR/stop_server.sh" "$INSTALL_DIR/stop_server.sh"
sudo cp "$SCRIPT_DIR/update_bedrock.sh" "$INSTALL_DIR/update_bedrock.sh"
sudo chmod +x "$INSTALL_DIR/start_server.sh" "$INSTALL_DIR/stop_server.sh" "$INSTALL_DIR/update_bedrock.sh"
sudo chown minecraft:minecraft "$INSTALL_DIR"/*.sh


# 3. Copy systemd service file
sudo cp "$SCRIPT_DIR/minecraft.service" "$SERVICE_FILE"
sudo systemctl daemon-reload
sudo systemctl enable minecraft.service


# 4. Schedule weekly update with cron (runs every Monday at 3am)
CRON_JOB="0 3 * * 1 su - minecraft -c '$INSTALL_DIR/update_bedrock.sh >/dev/null 2>&1'"
(crontab -l 2>/dev/null | grep -v 'update_bedrock.sh'; echo "$CRON_JOB") | crontab -

echo "Minecraft Bedrock server installed and configured."
echo "Use 'sudo systemctl start minecraft' to start the server."
