#!/usr/bin/env bash

# Define the app names
apps=("springj8" "springj21" "springnative")

while true; do
    all_running=true
    for app in "${apps[@]}"; do
        status=$(cf app "$app" | grep '#0' | awk '{print $2}')
        if [ "$status" != "running" ]; then
            all_running=false
            break
        fi
    done

    if [ "$all_running" = true ]; then
        break
    fi
    echo "Waiting for all apps to be running..."
    sleep 5
done

echo "--------------------------------------------------------------------------------------------"
echo "Same apps running on Cloud Foundry"
echo "--------------------------------------------------------------------------------------------"
cf app springj8 | grep "#0"
cf app springj21 | grep "#0"
cf app springnative | grep "#0"