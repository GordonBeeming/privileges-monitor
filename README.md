# 🛡️ macOS Privileges Monitor

A lightweight **Monitor & Alert** system for macOS. Instead of blocking administrative access and becoming a bottleneck for schoolwork or development, this system allows users to elevate their privileges while ensuring you get an alert the moment it happens.

> [!IMPORTANT]
> This solution is not a foolproof security execution (and neither is the [SAP Privileges app](https://github.com/SAP/macOS-enterprise-privileges) itself). If a user has admin rights, they technically have the power to disable these monitors. This setup is designed for a **"Trust but Verify"** environment—it provides visibility and reduces friction, but it requires a baseline of trust.
> 
> If you are looking for a more "complete" lockdown, you can follow [this guide on locking down macOS settings](https://gordonbeeming.com/blog/2025-11-22/locking-down-settings-the-real-way). However, be aware that the higher level of control comes with its own administrative headaches.

## 🚀 How it Works

This monitoring system uses **two complementary approaches**:

### 1. SAP Privileges Integration (Recommended)
* **Direct Webhook:** SAP Privileges calls `privileges_post_change.sh` directly when a user's privileges change
* **Immediate Alerts:** No log streaming needed—notifications sent instantly via webhook
* **Reliable:** Uses the official SAP Privileges `PostChangeExecutablePath` mechanism
* **Structured Data:** Includes user, machine, state, timestamp, and optional reason

### 2. Sudo Monitoring (Fallback/Additional)
* **Log Stream Monitor:** A daemon (`privileges_sudo_monitor.sh`) monitors system logs for unauthorized sudo attempts
* **Event Queue:** Detected events are stored as JSON files in `/Users/Shared/privileges_queue`
* **Periodic Sync:** Another daemon (`privileges_sync_simple.sh`) runs every 5 minutes to send queued events
* **Offline Queue:** Events are retained until internet connectivity is restored

## 📊 JSON Schema

```json
{
  "machine": "blastoise",
  "user": "gordonbeeming",
  "state": "admin|user|unauthorized_sudo",
  "message": "User promoted to Administrator",
  "reason": "Installing development tools",
  "time": "2026-01-28T12:15:00Z"
}
```

## 🛠️ Setup

### 1. Prerequisites

Ensure you have the [SAP Privileges app](https://github.com/SAP/macOS-enterprise-privileges) installed.

### 2. Configuration

Copy the template and configure your settings:

```bash
cp privileges_config.env.template privileges_config.env
```

Edit `privileges_config.env` and add your `POST_URL` and `AUTH_TOKEN`:

```bash
# Your ntfy.sh or webhook URL
POST_URL="https://ntfy.sh/your_topic_here"

# Your ntfy.sh access token (Bearer token)
AUTH_TOKEN="tk_your_token_here"

# The name used in notifications
MACHINE_NAME=$(scutil --get LocalHostName)
```

### 3. Installation

Run the setup script:

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
- Create necessary folders in `/usr/local/bin/privileges-monitor/`
- Copy and install all scripts
- Register the LaunchDaemons for sudo monitoring
- Copy the configuration profile to `~/Downloads/PrivilegesMonitor.mobileconfig`
- Restart the Privileges app automatically

### 4. Install the Configuration Profile (CRITICAL STEP!)

**The configuration profile MUST be manually installed** for the webhook integration to work:

1. Open `~/Downloads/PrivilegesMonitor.mobileconfig` (copied there by setup.sh)
2. Double-click to open it
3. Go to **System Settings → Privacy & Security → Profiles**
4. Find **"Privileges Monitor Configuration"** and click Install
5. Authenticate with your admin password when prompted

**Without this step, the immediate webhook notifications won't work!** You'll only get delayed notifications from the log monitor.

### 5. Verification

To verify everything is working:

1. **Check daemons are running:**
   ```bash
   sudo launchctl list | grep gordonbeeming
   ```
   You should see:
   - `com.gordonbeeming.privileges.sync` - Syncs queued sudo events every 5 minutes
   - `com.gordonbeeming.sudo.monitor` - Monitors for unauthorized sudo attempts

2. **Test privilege changes:**
   - Click the Privileges icon in your menu bar
   - You'll be prompted for:
     - Touch ID authentication
     - A reason (10-250 characters)
     - Time duration (default 20 min, max 60 min)
   - Grant yourself admin rights
   - Check your ntfy.sh notifications - you should receive an immediate alert with the reason!

3. **Check logs:**
   ```bash
   log show --predicate 'process == "privileges-monitor"' --last 5m
   ```

## 🔧 Configuration Details

The setup includes:

- **Touch ID Required:** Users must authenticate with Touch ID (or password if unavailable)
- **Reason Required:** Users must provide a reason (10-250 characters) for requesting admin rights
- **Time Limits:** Default 20 minutes, maximum 60 minutes (user can choose)
- **Webhook Integration:** Direct integration with SAP Privileges for immediate notifications
- **Sudo Monitoring:** Continuous monitoring for unauthorized sudo attempts

---

## 📝 Troubleshooting

**Quick Check:** Run the automated troubleshooting script:
```bash
./troubleshoot.sh
```

This will check:
- Configuration profile installation
- Installed scripts
- Daemon status
- Event queue
- ntfy.sh connectivity
- Recent logs

### Common Issues

* **No notifications received?** 
  - Check that your `AUTH_TOKEN` is correct in `privileges_config.env`
  - Verify the scripts were copied: `ls -la /usr/local/bin/privileges-monitor/`
  - Check logs: `log show --predicate 'process == "privileges-monitor"' --last 5m`

* **Privileges app not prompting for Touch ID or reason?**
  - **Most likely cause:** The configuration profile wasn't installed properly
  - Check if it's installed: `sudo profiles show | grep -A 20 "corp.sap.privileges"`
  - If not installed, go to System Settings → Privacy & Security → Profiles
  - Install the "Privileges Monitor Configuration" profile
  - If you don't see it there, reinstall from `~/Downloads/PrivilegesMonitor.mobileconfig`
  - Restart the Privileges app: `killall PrivilegesAgent Privileges; open -a Privileges`

* **No immediate notifications when changing privileges?**
  - This means the PostChangeExecutablePath isn't being called
  - The configuration profile is NOT installed or not loaded
  - Verify: `sudo profiles show | grep "PostChangeExecutablePath"`
  - If you see the path, restart Privileges daemons:
    ```bash
    sudo launchctl kickstart -k system/corp.sap.privileges.daemon
    killall PrivilegesAgent Privileges
    ```
  - If you don't see it, the profile isn't installed - go back to step 4

* **Permission Denied?** 
  - Ensure the terminal has **Full Disk Access** in System Settings to allow `log stream` to read system logs

* **Manual sync test:** 
  ```bash
  sudo /usr/local/bin/privileges-monitor/privileges_sync.sh
  ```

## 📁 Files Overview

- **`privileges_post_change.sh`** - Webhook called by SAP Privileges on privilege changes
- **`privileges_sync.sh`** - Syncs queued sudo events to ntfy.sh with nice formatting
- **`privileges_sudo_monitor.sh`** - Monitors system logs for unauthorized sudo attempts
- **`com.sap.privileges.webhook.mobileconfig`** - SAP Privileges configuration profile (Touch ID, reason, timeouts, webhook)
- **`com.gordonbeeming.privileges.sync.plist`** - LaunchDaemon for syncing queued events
- **`com.gordonbeeming.sudo.monitor.plist`** - LaunchDaemon for sudo monitoring
