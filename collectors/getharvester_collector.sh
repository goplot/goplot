#!/bin/bash
# This script checks the status of the chia_harvester process and writes the up/down metric to the .prom file
# It also gets Chia farm plots and space and writes those to the .prom file
# Sleep for a time to offset from other jobs
sleep 13
# Set the location of the textfile collector directory
prom_collector_dir="/etc/prometheus/collectors"
# Set the name for the harvester status .prom file
harvester_status_prom_file="$prom_collector_dir/harvester_status.prom"
harvesterstats_prom_file="$prom_collector_dir/harvesterstats.prom"
# Set the Chia venv directory
chia_venv_dir="/etc/chia/chia-blockchain"
# Check that the chia_harvester process is running, but without "defunct"
ps_harvester="$(ps -eaf | grep 'chia_harvester' | grep -v 'defunct' | grep -v 'grep' -c)"
# If there is one process then things must be good, so set the status to up
if [[ $ps_harvester == "1" ]]; then
    harvester_status=1
# Otherwise there must be something wrong, so set the status to down
else
    harvester_status=0
fi
# Write the status to the prom file
{ echo "# HELP farm harvester status Chia harvester status";
echo "# TYPE farm_harvester_status gauge";
echo "farm_harvester_status $harvester_status"; } > $harvester_status_prom_file
# Activate the chia venv
cd $chia_venv_dir
. ./activate
# Get the chia farm summary
chia_farm_summary="`chia farm summary`"
# Get the harvester-specific farm metrics and write it to the prom file; problems with delay using sponge/tee here, so...
farm_plot_count="$(echo "$chia_farm_summary" | grep 'Plot count' | sed 's/.*count: //g')"
farm_plots_size="$(echo "$chia_farm_summary" | grep 'Total size of plots' | sed 's/.*plots: //g' | sed 's/..iB//g')"
{ echo "# HELP farm_plot_count Number of Chia farm plots";
echo "# TYPE farm_plot_count counter";
echo "farm_plot_count" $farm_plot_count;
echo "# HELP farm_plots_size Total size of Chia farm plots";
echo "# TYPE farm_plots_size gauge";
echo "farm_plots_size" $farm_plots_size; } > $harvesterstats_prom_file
# Politely deactivate the venv
deactivate
