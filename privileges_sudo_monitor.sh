#!/bin/bash
QUEUE_DIR="/Users/Shared/privileges_queue"
MACHINE_NAME=$(scutil --get LocalHostName)

mkdir -p "$QUEUE_DIR"
chmod 777 "$QUEUE_DIR"

# Broaden the filter to any process containing 'Privileges' or the sudo error
log stream --predicate 'process CONTAINS "Privileges" OR (process == "sudo" AND eventMessage CONTAINS "not in the sudoers file")' | while read -r line; do
    TIMESTAMP=$(date +%s)
    CURRENT_USER=$(stat -f "%Su" /dev/console)
    
    if [[ "$line" == *"now has administrator privileges"* ]]; then
        STATE="admin"
        MSG="User promoted to Administrator"
    elif [[ "$line" == *"now has standard user privileges"* ]]; then
        STATE="user"
        MSG="User demoted to Standard User"
    elif [[ "$line" == *"not in the sudoers file"* ]]; then
        STATE="unauthorized_sudo"
        MSG="Unauthorized sudo attempt detected."
    else
        continue
    fi

    cat <<EOF > "$QUEUE_DIR/event_$TIMESTAMP.json"
{
  "machine": "$MACHINE_NAME",
  "user": "$CURRENT_USER",
  "state": "$STATE",
  "message": "$MSG",
  "time": "$(date)"
}
EOF
    chmod 666 "$QUEUE_DIR/event_$TIMESTAMP.json"
done