#!/bin/bash
source /usr/local/bin/privileges-monitor/privileges_config.env
QUEUE_DIR="/Users/Shared/privileges_queue"

# Check for internet
ping -c 1 1.1.1.1 > /dev/null 2>&1
if [ $? -ne 0 ]; then exit 1; fi

for file in "$QUEUE_DIR"/*.json; do
    [ -e "$file" ] || continue
    payload=$(cat "$file")
    
    curl -H "Title: Privilege Change: $MACHINE_NAME" \
         -H "Priority: 3" \
         -H "Tags: key" \
         -d "$payload" "$POST_URL"
         
    if [ $? -eq 0 ]; then rm "$file"; fi
done