#!/bin/bash
# Install SAP Privileges configuration profile

PROFILE_SOURCE="$(pwd)/com.sap.privileges.config.mobileconfig"
PROFILE_DEST="$HOME/Downloads/SAPPrivilegesConfig.mobileconfig"

echo "📄 Installing SAP Privileges Configuration Profile"
echo ""

# Check if profile exists
if [ ! -f "$PROFILE_SOURCE" ]; then
    echo "❌ Profile not found: $PROFILE_SOURCE"
    exit 1
fi

# Copy to Downloads
cp "$PROFILE_SOURCE" "$PROFILE_DEST"

echo "Profile copied to: $PROFILE_DEST"
echo ""
echo "Opening profile for installation..."
echo ""

# Open the profile
open "$PROFILE_DEST"

echo "📝 Next steps:"
echo "   1. The profile will open in System Settings"
echo "   2. Click 'Install' (you may need to scroll down)"
echo "   3. Enter your admin password when prompted"
echo "   4. Press Enter here when done..."
echo ""
read -p "Press Enter after installing the profile: "

echo ""
echo "🔄 Restarting SAP Privileges..."
sudo launchctl kickstart -k system/corp.sap.privileges.daemon 2>/dev/null || true
killall PrivilegesAgent 2>/dev/null || true
killall Privileges 2>/dev/null || true

sleep 2

echo ""
echo "✅ Setup complete!"
echo ""
echo "🧪 Test it:"
echo "   1. Open the Privileges app (menu bar icon)"
echo "   2. Click to toggle admin privileges"
echo "   3. You should see:"
echo "      • Touch ID authentication prompt"
echo "      • Reason input dialog (10-250 characters)"
echo "      • Time duration selector"
echo "   4. Check your ntfy.sh topic for the notification!"
echo ""
