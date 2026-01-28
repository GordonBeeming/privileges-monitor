#!/bin/bash
# This script is called by SAP Privileges when user privileges change
# Arguments: $1 = username, $2 = state (admin|user), $3 = reason (optional)

source /usr/local/bin/privileges-monitor/privileges_config.env

USERNAME="$1"
STATE="$2"
REASON="${3:-}"
MACHINE_NAME=$(scutil --get LocalHostName)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Validate required data - don't send if missing critical info
if [[ -z "$MACHINE_NAME" ]] || [[ -z "$USERNAME" ]] || [[ -z "$STATE" ]]; then
    logger -t "privileges-monitor" "Skipping notification - missing required data (machine: '$MACHINE_NAME', user: '$USERNAME', state: '$STATE')"
    exit 0
fi

# Determine message and emoji based on state
if [[ "$STATE" == "admin" ]]; then
    MSG="User promoted to Administrator"
    EMOJI="key"
    PRIORITY="high"
    PRIORITY_NUM=4
else
    MSG="User demoted to Standard User"
    EMOJI="lock"
    PRIORITY="default"
    PRIORITY_NUM=3
fi

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "machine": "$MACHINE_NAME",
  "user": "$USERNAME",
  "state": "$STATE",
  "message": "$MSG",
  "reason": "$REASON",
  "time": "$TIMESTAMP"
}
EOF
)

# Create formatted notification message
NOTIFICATION_MSG="Machine: $MACHINE_NAME
User: $USERNAME
Status: $MSG"

# Add reason if present
if [[ -n "$REASON" ]]; then
    NOTIFICATION_MSG="$NOTIFICATION_MSG
Reason: $REASON"
fi

NOTIFICATION_MSG="$NOTIFICATION_MSG
Time: $TIMESTAMP"

# Send to ntfy.sh with authentication
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Title: Privilege Change: $MACHINE_NAME" \
    -H "Priority: $PRIORITY_NUM" \
    -H "Tags: $EMOJI" \
    -d "$NOTIFICATION_MSG" \
    "$POST_URL" 2>&1)

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

# Log result
if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
    logger -t "privileges-monitor" "Successfully sent privilege change notification for $USERNAME ($STATE)"
    exit 0
else
    logger -t "privileges-monitor" "Failed to send privilege change notification: HTTP $HTTP_CODE - $RESPONSE_BODY"
    exit 1
fi
