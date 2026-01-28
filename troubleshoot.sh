#!/bin/bash
# Troubleshooting script for Privileges Monitor

echo "=================================="
echo "Privileges Monitor Troubleshooting"
echo "=================================="
echo ""

# Check 1: Configuration Profile
echo "1. Checking Configuration Profile..."
if sudo profiles show | grep -q "corp.sap.privileges"; then
    echo "   ✅ Configuration profile is installed"
    if sudo profiles show | grep -q "PostChangeExecutablePath"; then
        echo "   ✅ PostChangeExecutablePath is configured"
    else
        echo "   ❌ PostChangeExecutablePath NOT found in profile"
        echo "      → The webhook won't be triggered on privilege changes"
        echo "      → Reinstall the profile from ~/Downloads/PrivilegesMonitor.mobileconfig"
    fi
else
    echo "   ❌ Configuration profile NOT installed"
    echo "      → Go to System Settings → Privacy & Security → Profiles"
    echo "      → Install 'Privileges Monitor Configuration' profile"
    echo "      → Or double-click ~/Downloads/PrivilegesMonitor.mobileconfig"
fi
echo ""

# Check 2: Scripts installed
echo "2. Checking installed scripts..."
if [ -d "/usr/local/bin/privileges-monitor" ]; then
    echo "   ✅ Scripts directory exists"
    for script in privileges_post_change.sh privileges_sync.sh privileges_sudo_monitor.sh privileges_config.env; do
        if [ -f "/usr/local/bin/privileges-monitor/$script" ]; then
            echo "   ✅ $script found"
        else
            echo "   ❌ $script MISSING"
        fi
    done
else
    echo "   ❌ Scripts directory NOT found"
    echo "      → Run ./setup.sh to install"
fi
echo ""

# Check 3: LaunchDaemons
echo "3. Checking LaunchDaemons..."
SYNC_STATUS=$(sudo launchctl list | grep com.gordonbeeming.privileges.sync | awk '{print $1}')
MONITOR_STATUS=$(sudo launchctl list | grep com.gordonbeeming.sudo.monitor | awk '{print $1}')

if [ "$SYNC_STATUS" = "-" ]; then
    echo "   ❌ Sync daemon is NOT running (status: -)"
    echo "      → Restart it: sudo launchctl kickstart -k system/com.gordonbeeming.privileges.sync"
elif [ -n "$SYNC_STATUS" ]; then
    echo "   ✅ Sync daemon is running (PID: $SYNC_STATUS)"
else
    echo "   ❌ Sync daemon NOT loaded"
    echo "      → Load it: sudo launchctl load /Library/LaunchDaemons/com.gordonbeeming.privileges.sync.plist"
fi

if [ "$MONITOR_STATUS" = "-" ]; then
    echo "   ❌ Monitor daemon is NOT running (status: -)"
    echo "      → Restart it: sudo launchctl kickstart -k system/com.gordonbeeming.sudo.monitor"
elif [ -n "$MONITOR_STATUS" ]; then
    echo "   ✅ Monitor daemon is running (PID: $MONITOR_STATUS)"
else
    echo "   ❌ Monitor daemon NOT loaded"
    echo "      → Load it: sudo launchctl load /Library/LaunchDaemons/com.gordonbeeming.sudo.monitor.plist"
fi
echo ""

# Check 4: Queue
echo "4. Checking event queue..."
if [ -d "/Users/Shared/privileges_queue" ]; then
    QUEUE_COUNT=$(ls -1 /Users/Shared/privileges_queue/*.json 2>/dev/null | wc -l | tr -d ' ')
    if [ "$QUEUE_COUNT" -gt 0 ]; then
        echo "   ⚠️  $QUEUE_COUNT event(s) in queue"
        echo "      → Events are waiting to be sent"
        echo "      → Test sync manually: sudo /usr/local/bin/privileges-monitor/privileges_sync.sh"
    else
        echo "   ✅ Queue is empty (no pending events)"
    fi
else
    echo "   ❌ Queue directory doesn't exist"
    echo "      → Run ./setup.sh to create it"
fi
echo ""

# Check 5: ntfy.sh connectivity
echo "5. Testing ntfy.sh connectivity..."
if [ -f "/usr/local/bin/privileges-monitor/privileges_config.env" ]; then
    source /usr/local/bin/privileges-monitor/privileges_config.env
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Title: Troubleshooting Test" \
        -H "Priority: 3" \
        -H "Tags: shield" \
        -d "This is a test from privileges-monitor troubleshooter" \
        "$POST_URL" 2>&1)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
        echo "   ✅ ntfy.sh is reachable (HTTP $HTTP_CODE)"
        echo "      → Check your ntfy.sh app/web for the test notification"
    else
        echo "   ❌ Failed to reach ntfy.sh (HTTP $HTTP_CODE)"
        echo "      → Check your POST_URL and AUTH_TOKEN in privileges_config.env"
        RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')
        echo "      → Response: $RESPONSE_BODY"
    fi
else
    echo "   ❌ Config file not found"
    echo "      → Check privileges_config.env exists"
fi
echo ""

# Check 6: Recent logs
echo "6. Recent logs (last 5 minutes)..."
log show --predicate 'process == "privileges-monitor"' --last 5m --info 2>/dev/null | tail -10
echo ""

echo "=================================="
echo "Troubleshooting Complete"
echo "=================================="
