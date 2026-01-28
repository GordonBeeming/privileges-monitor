#!/bin/bash
SOURCE_DIR=$(pwd)
BIN_DIR="/usr/local/bin/privileges-monitor"
QUEUE_DIR="/Users/Shared/privileges_queue"
DAEMON_DIR="/Library/LaunchDaemons"

echo "🚀 Running Setup..."

sudo mkdir -p "$BIN_DIR"
sudo mkdir -p "$QUEUE_DIR"
sudo chmod 777 "$QUEUE_DIR"

# Copy files to install dir
sudo cp "$SOURCE_DIR/privileges_sudo_monitor.sh" "$BIN_DIR/"
sudo cp "$SOURCE_DIR/privileges_sync_simple.sh" "$BIN_DIR/"
sudo cp "$SOURCE_DIR/privileges_config.env" "$BIN_DIR/"
sudo chmod +x "$BIN_DIR"/*.sh

# Refresh Daemons
sudo launchctl unload "$DAEMON_DIR/com.gordonbeeming.privileges.sync.plist" 2>/dev/null
sudo launchctl unload "$DAEMON_DIR/com.gordonbeeming.sudo.monitor.plist" 2>/dev/null

sudo cp "$SOURCE_DIR"/*.plist "$DAEMON_DIR/"
sudo chown root:wheel "$DAEMON_DIR"/com.gordonbeeming.*.plist
sudo chmod 644 "$DAEMON_DIR"/com.gordonbeeming.*.plist

sudo launchctl load "$DAEMON_DIR/com.gordonbeeming.privileges.sync.plist"
sudo launchctl load "$DAEMON_DIR/com.gordonbeeming.sudo.monitor.plist"

echo "✅ Setup complete."