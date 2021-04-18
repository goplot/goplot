#!/bin/bash
# harvester_ps.sh
#
# This script checks for a <defunct> chia_harvester process and if it exists restarts the harvester
# Change the restart command to "chia stop all -d" to restart everything
# Run in cron every five minutes or so like this
#*/5 * * * * /etc/chia/goplot/misc/harvester_ps.sh
#
# Set the goplot root directory
working_dir="/etc/chia/goplot"
# Set a log file for event messages
log="${working_dir}/logs/mon_events.log"
# Check for a defunct chia_harvester process using ps
defunct_harvester="$(ps -eaf | grep 'chia_harvester' | grep 'defunct' | grep -v 'grep' -c)"
# If there is a defunct process then it must not be harvesting, we need to restart it
if [[ $defunct_harvester > "0" ]]; then
# Set the chia venv directory
chia_venv_dir="/etc/chia/chia-blockchain"
# Activate the chia virtual environment
cd $chia_venv_dir
. ./activate
# Send the fact that this is happening to a log somewhere
echo "$(date)  harvester_ps_defunct     :WARN    chia_harvester process <defunct>; restarting harvester" >> $log
# stop the harvester using "chia stop"
chia stop harvester
# Sleep for a few seconds just to be sure the process is cleared out
sleep 5
# Start the harvester using "chia start"
chia start harvester
else
# Send the successful check to the log
echo "$(date)  harvester_ps     :INFO    chia_harvester process is not defunct" >> $log
fi
