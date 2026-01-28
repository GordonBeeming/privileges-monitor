#!/bin/bash
# Quick script to install the Privileges Monitor configuration profile

echo "🔧 Installing Privileges Monitor Configuration Profile..."
echo ""

PROFILE_PATH="$HOME/Downloads/PrivilegesMonitor.mobileconfig"

if [ ! -f "$PROFILE_PATH" ]; then
    echo "❌ Profile not found at $PROFILE_PATH"
    echo "   Run ./setup.sh first to copy the profile to Downloads"
    exit 1
fi

echo "📄 Profile location: $PROFILE_PATH"
echo ""
echo "Opening the profile for installation..."
echo ""
echo "Next steps:"
echo "1. The profile will open in System Settings"
echo "2. Click 'Install' or 'Install Profile'"
echo "3. Enter your admin password when prompted"
echo "4. Restart the Privileges app"
echo ""

# Open the profile
open "$PROFILE_PATH"

echo "⏳ Waiting for you to install the profile..."
echo "   (Press Enter after you've installed it)"
read

echo ""
echo "🔄 Restarting Privileges components..."
sudo launchctl kickstart -k system/corp.sap.privileges.daemon 2>/dev/null
killall PrivilegesAgent 2>/dev/null
killall Privileges 2>/dev/null
sleep 2
open -a Privileges 2>/dev/null

echo ""
echo "✅ Done! Test by:"
echo "   1. Click the Privileges app"
echo "   2. You should be prompted for Touch ID + a reason"
echo "   3. Check ntfy.sh for immediate notification!"
echo ""
