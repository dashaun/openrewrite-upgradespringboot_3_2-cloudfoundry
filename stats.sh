#!/usr/bin/env bash

while true; do
    # Get the line containing '#0'
    status1=$(cf app springj8 | grep '#0' | awk '{print $2}')
    status2=$(cf app springj21 | grep '#0' | awk '{print $2}')
    status3=$(cf app springnative | grep '#0' | awk '{print $2}')

    
    # Check if the status1 is 'running'
    if [ "$status1" == "running" && "$status2" == "running" && "$status3" == "running" ]; 
    then
        break
    fi
    
    # Wait for a few seconds before checking again
    sleep 5
done
echo "--------------------------------------------------------------------------------------------"
echo "Same apps running on Cloud Foundry"
echo "--------------------------------------------------------------------------------------------"
cf app springj8 | grep "#0"
cf app springj21 | grep "#0"
cf app springnative | grep "#0"