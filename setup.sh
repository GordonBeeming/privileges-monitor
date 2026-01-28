#!/bin/bash
SOURCE_DIR=$(pwd)
BIN_DIR="/usr/local/bin/privileges-monitor"
QUEUE_DIR="/Users/Shared/privileges_queue"
DAEMON_DIR="/Library/LaunchDaemons"
PROFILES_DIR="/Library/Managed Preferences"

echo "🚀 Running Setup..."

# Create directories
sudo mkdir -p "$BIN_DIR"
sudo mkdir -p "$QUEUE_DIR"
sudo chmod 777 "$QUEUE_DIR"

# Copy scripts to install dir
sudo cp "$SOURCE_DIR/privileges_sudo_monitor.sh" "$BIN_DIR/"
sudo cp "$SOURCE_DIR/privileges_sync.sh" "$BIN_DIR/"
sudo cp "$SOURCE_DIR/privileges_post_change.sh" "$BIN_DIR/"
sudo cp "$SOURCE_DIR/privileges_config.env" "$BIN_DIR/"
sudo chmod +x "$BIN_DIR"/*.sh

# Refresh Daemons
sudo launchctl unload "$DAEMON_DIR/com.gordonbeeming.privileges.sync.plist" 2>/dev/null
sudo launchctl unload "$DAEMON_DIR/com.gordonbeeming.sudo.monitor.plist" 2>/dev/null

# Copy LaunchDaemon plists (only the two we need, not the Privileges config plist)
sudo cp "$SOURCE_DIR/com.gordonbeeming.privileges.sync.plist" "$DAEMON_DIR/"
sudo cp "$SOURCE_DIR/com.gordonbeeming.sudo.monitor.plist" "$DAEMON_DIR/"
sudo chown root:wheel "$DAEMON_DIR"/com.gordonbeeming.*.plist
sudo chmod 644 "$DAEMON_DIR"/com.gordonbeeming.*.plist

sudo launchctl load "$DAEMON_DIR/com.gordonbeeming.privileges.sync.plist"
sudo launchctl load "$DAEMON_DIR/com.gordonbeeming.sudo.monitor.plist"

# Copy configuration profile to user's Downloads for manual installation
echo "📄 Copying Privileges configuration profile to ~/Downloads..."
cp "$SOURCE_DIR/com.sap.privileges.webhook.plist" "$HOME/Downloads/PrivilegesMonitor.mobileconfig"

# Clean up old scripts if they exist
sudo rm -f "$BIN_DIR/privileges_sync_simple.sh" 2>/dev/null

# Restart Privileges daemons to pick up any config changes
echo "🔄 Restarting Privileges daemons..."
sudo launchctl kickstart -k system/corp.sap.privileges.daemon 2>/dev/null || true
sudo launchctl kickstart -k system/corp.sap.privileges.helper 2>/dev/null || true
killall PrivilegesAgent 2>/dev/null || true
killall Privileges 2>/dev/null || true
sleep 1
open -a Privileges 2>/dev/null || echo "   ⚠️  Privileges app not found - please install SAP Privileges first"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Install the configuration profile:"
echo "      - Open ~/Downloads/PrivilegesMonitor.mobileconfig"
echo "      - Double-click to install it"
echo "      - Go to System Settings > Privacy & Security > Profiles"
echo "      - Install the 'Privileges Monitor Configuration' profile"
echo ""
echo "   2. Verify daemons are running:"
echo "      sudo launchctl list | grep gordonbeeming"
echo ""
echo "   3. Test by toggling privileges in the SAP Privileges app"
echo "      - You should be prompted for Touch ID + a reason"
echo "      - Check ntfy.sh for immediate notifications!"
echo ""