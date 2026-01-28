# 🛡️ macOS Privileges Monitor

A lightweight **Monitor & Alert** system for macOS. Instead of blocking administrative access and becoming a bottleneck for schoolwork or development, this system allows users to elevate their privileges while ensuring you get an alert the moment it happens.

> [!IMPORTANT]
> This solution is not a foolproof security execution (and neither is the [SAP Privileges app](https://github.com/SAP/macOS-enterprise-privileges) itself). If a user has admin rights, they technically have the power to disable these monitors. This setup is designed for a **"Trust but Verify"** environment—it provides visibility and reduces friction, but it requires a baseline of trust.
> 
> If you are looking for a more "complete" lockdown, you can follow [this guide on locking down macOS settings](https://gordonbeeming.com/blog/2025-11-22/locking-down-settings-the-real-way). However, be aware that the higher level of control comes with its own administrative headaches.

## 🚀 How it Works

1. **The Log Monitor:** A background daemon (`privileges_sudo_monitor.sh`) runs as root and streams system logs in real-time. It uses specific predicates to catch:
* **SAP Privileges Events:** "User now has administrator privileges" or "standard user privileges".
* **Unauthorized Sudo:** Any attempt by a non-sudoer to use the `sudo` command.


2. **The Event Queue:** When an event is detected, the monitor drops a JSON "incident" file into `/Users/Shared/privileges_queue`.
3. **The Connectivity Check:** A second LaunchDaemon (`privileges_sync_simple.sh`) wakes up every 5 minutes and pings Cloudflare DNS (**1.1.1.1**) to check for internet connectivity.
4. **The Alert:** If online, it drains the queue by POSTing the JSON events to your configured **ntfy.sh** endpoint and deletes the processed files.

## 📂 Sync Options

Depending on your backend, you can choose which sync script to use in your `.plist`:

* **`privileges_sync.sh` (Recommended for ntfy.sh):** Parses the JSON locally to inject "Pretty" headers like Titles, Emojis, and Priorities (Urgent for sudo, High for Admin).
* **`privileges_sync_simple.sh` (Best for Logic Apps/API):** Sends the raw JSON payload as-is. Best if you want to handle formatting and logic on the server side.

## 📊 JSON Schema

```json
{
  "machine": "blastoise",
  "user": "gordonbeeming",
  "state": "admin|user|unauthorized_sudo",
  "message": "User promoted to Administrator",
  "time": "Wed Jan 28 22:15:00 AEST 2026"
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

Edit `privileges_config.env` and add your `POST_URL`.

### 3. Installation

The `setup.sh` script is idempotent. It will create the necessary folders in `/usr/local/bin/privileges-monitor/`, copy the scripts, and register the LaunchDaemons.

```bash
chmod +x setup.sh
./setup.sh

```

### 4. Verification

Since this version uses **Log Streaming**, you do **not** need to register a script inside the Privileges App settings (which often triggers TCC permission errors). To verify:

1. Toggle your privileges in the menu bar.
2. Check the queue: `ls /Users/Shared/privileges_queue`
3. Verify the Daemons are running: `sudo launchctl list | grep gordonbeeming`

---

## 📝 Troubleshooting

* **No files in queue?** Ensure the monitor has started: `sudo launchctl load /Library/LaunchDaemons/com.gordonbeeming.sudo.monitor.plist`.
* **Permission Denied?** Ensure the terminal has **Full Disk Access** in System Settings to allow the `log stream` to read system logs.
* **Manual Sync Test:** Run `sudo /usr/local/bin/privileges-monitor/privileges_sync_simple.sh` to force an immediate upload.
