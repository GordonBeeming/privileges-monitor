#!/bin/bash
source /usr/local/bin/privileges-monitor/privileges_config.env
QUEUE_DIR="/Users/Shared/privileges_queue"

# Check for internet
ping -c 1 1.1.1.1 > /dev/null 2>&1
if [ $? -ne 0 ]; then exit 1; fi

for file in "$QUEUE_DIR"/*.json; do
    [ -e "$file" ] || continue
    
    # Parse JSON fields
    machine=$(grep -o '"machine":"[^"]*"' "$file" | cut -d'"' -f4)
    user=$(grep -o '"user":"[^"]*"' "$file" | cut -d'"' -f4)
    state=$(grep -o '"state":"[^"]*"' "$file" | cut -d'"' -f4)
    message=$(grep -o '"message":"[^"]*"' "$file" | cut -d'"' -f4)
    reason=$(grep -o '"reason":"[^"]*"' "$file" | cut -d'"' -f4)
    timestamp=$(grep -o '"time":"[^"]*"' "$file" | cut -d'"' -f4)
    
    # Determine title, emoji, and priority based on state
    case "$state" in
        "admin")
            TITLE="🔓 Admin Rights Granted"
            EMOJI="key"
            PRIORITY=4
            ;;
        "user")
            TITLE="🔒 Admin Rights Revoked"
            EMOJI="lock"
            PRIORITY=3
            ;;
        "unauthorized_sudo")
            TITLE="⚠️ Unauthorized Sudo Attempt"
            EMOJI="warning"
            PRIORITY=5
            ;;
        *)
            TITLE="Privilege Change"
            EMOJI="shield"
            PRIORITY=3
            ;;
    esac
    
    # Create formatted message for ntfy
    FORMATTED_MESSAGE="Machine: $machine
User: $user
Status: $message"
    
    # Add reason if present
    if [[ -n "$reason" ]]; then
        FORMATTED_MESSAGE="$FORMATTED_MESSAGE
Reason: $reason"
    fi
    
    FORMATTED_MESSAGE="$FORMATTED_MESSAGE
Time: $timestamp"
    
    # Send to ntfy.sh with authentication and formatted headers
    RESPONSE=$(curl -s -w "\n%{http_code}" \
         -H "Authorization: Bearer $AUTH_TOKEN" \
         -H "Title: $TITLE" \
         -H "Priority: $PRIORITY" \
         -H "Tags: $EMOJI" \
         -d "$FORMATTED_MESSAGE" \
         "$POST_URL" 2>&1)
    
    # Extract HTTP status code (last line)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    # Only delete file if HTTP response is 2xx (success)
    if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
        rm "$file"
        logger -t "privileges-monitor" "Successfully synced event for $user ($state)"
    else
        logger -t "privileges-monitor" "Failed to sync event (HTTP $HTTP_CODE): $file"
    fi
done
