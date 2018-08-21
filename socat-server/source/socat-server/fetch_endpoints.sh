#!/bin/bash

master_instance=$(/opt/treadmill/bin/treadmill admin show running|egrep "^$SOCAT_MASTER_APP#"|sort|tail -1)

if [[ $? != 0 ]]; then
    echo "Listing running instances failed!"
    exit 2
fi

if [ -z "$master_instance" ]; then
    echo "No instance of $master_app found!"
    exit 3
else
    endpoint_data=$(/opt/treadmill/bin/treadmill admin discovery $master_instance)
    if [[ $? != 0 ]]; then
        echo "Running discovery failed!"
        exit 4
    fi
    if [ -z "$endpoint_data" ]; then
        echo "No endpoint data found"
        exit 5
    fi

    echo "$endpoint_data"
fi

