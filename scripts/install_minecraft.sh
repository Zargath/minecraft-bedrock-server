#!/bin/zsh
# install_minecraft.sh - Fresh install of Minecraft Bedrock server using update_bedrock.sh
# Usage: sudo ./install_minecraft.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run the update script to fetch and install the latest server
sudo "$SCRIPT_DIR/update_bedrock.sh"

echo "Fresh Minecraft Bedrock server installed."
