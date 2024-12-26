#!/usr/bin/env bash

UPS_NAME="cyberpower"
LOG_PREFIX="NAS UPS"
MIN_PERCENT=30
# to enable these set them to 1
# test mode uses the fake upsc output from the file in the repo. Ideally replace this with your own for testing
TEST_MODE=0
SEND_NOTIFICATION=0
# set this to 1 to use the fake output from the output_of_ups.txt file. handy if you want to test different percentages when editing the script, whithout needing to wait for the ups to discharge
USE_FAKE_UPSC_OUTPUT=0

if [[ "$USE_FAKE_UPSC_OUTPUT" -eq 1 ]]; then
    function upsc(){
        cat ./output_of_ups.txt
    }
fi

function notify(){
    echo -en ""
    if [[ "$SEND_NOTIFICATION" -eq 0 ]]; then
        return
    fi
    if [[ "$TEST_MODE" -eq 0 ]]; then
        /root/scripts/telegram_notify.sh $@
    else
        ~/scrips/telegram_notify.sh $@
    fi
}

function time_to_die(){
    FLAG_FILE="/tmp/ups_is_shutting_down"
    if [[ -f "$FLAG_FILE" ]]; then
        echo "$(date) $LOG_PREFIX Shutdown already in progress. Skipping."
        return
    fi

    echo "$(date) $LOG_PREFIX Going to shut down"
    notify "$LOG_PREFIX Going to shut down"
    touch "$FLAG_FILE"
    sleep 1
    if [[ "$TEST_MODE" -eq 0 ]]; then
        echo "$(date) $LOG_PREFIX Executing shutdown command."
        /sbin/shutdown -h now
    else
        echo "$(date) $LOG_PREFIX Test mode enabled. Shutdown skipped."
    fi
}

# Retrieve UPS status and battery charge using upsc
UPS_STATUS=$(upsc $UPS_NAME@localhost | grep -i "ups.status:" | awk '{print $2}')
BATTERY_CHARGE=$(upsc $UPS_NAME@localhost | grep -i "battery.charge:" | awk '{print $2}' | tr -d '\n')

echo "$(date) $LOG_PREFIX status is $UPS_STATUS charge is $BATTERY_CHARGE"

if [[ "$UPS_STATUS" == "OB" ]]; then
    echo "$(date) $LOG_PREFIX power lost ${BATTERY_CHARGE}%"
    notify "$LOG_PREFIX power lost ${BATTERY_CHARGE}%"
fi
#if [[ "$UPS_STATUS" == "OB DISCHRG" && "$BATTERY_CHARGE" -lt MIN_PERCENT ]]; then
if [[ "$UPS_STATUS" == "OB" && "$BATTERY_CHARGE" -lt $MIN_PERCENT ]]; then
    time_to_die
fi
