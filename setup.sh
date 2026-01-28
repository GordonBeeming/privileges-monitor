#!/bin/bash
# SAP Privileges Monitor - Simple Setup

SOURCE_DIR=$(pwd)
BIN_DIR="/usr/local/bin/privileges-monitor"

echo "🚀 Setting up SAP Privileges Monitor"
echo ""

# Check if config exists
if [ ! -f "$SOURCE_DIR/privileges_config.env" ]; then
    echo "❌ Error: privileges_config.env not found"
    echo "   Copy privileges_config.env.template to privileges_config.env"
    echo "   and add your ntfy.sh URL and token"
    exit 1
fi

# Load config to validate
source "$SOURCE_DIR/privileges_config.env"

if [ -z "$POST_URL" ]; then
    echo "❌ Error: POST_URL not set in privileges_config.env"
    exit 1
fi

if [ -z "$AUTH_TOKEN" ]; then
    echo "⚠️  Warning: AUTH_TOKEN not set - notifications may fail if your topic requires auth"
fi

# Create directory and copy scripts
echo "📂 Installing scripts to $BIN_DIR..."
sudo mkdir -p "$BIN_DIR"
sudo cp "$SOURCE_DIR/privileges_post_change.sh" "$BIN_DIR/"
sudo cp "$SOURCE_DIR/privileges_config.env" "$BIN_DIR/"
sudo chmod +x "$BIN_DIR"/*.sh

echo "✅ Scripts installed!"
echo ""
echo "📋 Next step: Install the configuration profile"
echo ""
echo "Run: ./install_profile.sh"
echo ""
