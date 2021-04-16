#!/bin/bash
# Set the chia venv directory
chia_venv_dir="/etc/chia/chia-blockchain"
# Activate the chia virtual environment
cd $chia_venv_dir
. ./activate
# Get the chia full node summary
chia_show_fullnode="`chia show -s`"
# Parse the line with the sync status and get the staus message
chia_fullnode_syncstatus="$(echo "$chia_show_fullnode" | grep 'Current Blockchain Status' | sed 's/.*Status: //g')"
# Set the sync status in a variable
if [[ $chia_fullnode_syncstatus == "Full Node Synced" ]]; then
	    farm_fullnode_syncstatus=1
    else
	        farm_fullnode_syncstatus=0
fi
# Write the Prometheus metric to stdout, it is assumed you use something like sponge to tee before outputing to the prom file
echo "# HELP farm_fullnode_syncstatus Chia full node sync status"
echo "# TYPE farm_fullnode_syncstatus gauge"
echo "farm_fullnode_syncstatus" $farm_fullnode_syncstatus
# Get the chia farm summary
chia_farm_summary="`chia farm summary`"
# Parse the line with the farming status and get the staus message
chia_farming_status="$(echo "$chia_farm_summary" | grep 'Farming status' | sed 's/.*status: //g')"
# Set the farming status in a variable
if [[ $chia_farming_status == "Farming" ]]; then
	    farm_farmer_farmstatus=1
    else
	        farm_farmer_farmstatus=0
fi
# Output the farming status
echo "# HELP farm_farmer_farmstatus Chia farmer farming status"
echo "# TYPE farm_farmer_farmstatus gauge"
echo "farm_farmer_farmstatus" $farm_farmer_farmstatus
# The rest of these follow the same pattern of getting the metric data and writing to stdout
farm_fullnode_netspace="$(echo "$chia_show_fullnode" | grep 'Estimated network space' | sed 's/.*space: //g' | sed 's/..iB//g')"
echo "# HELP farm_fullnode_netspace Chia full node estimated network space"
echo "# TYPE farm_fullnode_netspace gauge"
echo "farm_fullnode_netspace" $farm_fullnode_netspace
farm_fullnode_difficulty="$(echo "$chia_show_fullnode" | grep 'Current difficulty' | sed 's/.*difficulty: //g')"
echo "# HELP farm_fullnode_difficulty Chia full node blockchain difficulty"
echo "# TYPE farm_fullnode_difficulty gauge"
echo "farm_fullnode_difficulty" $farm_fullnode_difficulty
farm_xch_farmed="$(echo "$chia_farm_summary" | grep 'Total chia farmed' | sed 's/.*farmed: //g')"
echo "# HELP farm_xch_farmed Chia full node estimated network space"
echo "# TYPE farm_xch_farmed counter"
echo "farm_xch_farmed" $farm_xch_farmed
# This section commented out so people don't show their last block won in community posts, uncomment if you want
#chia_fullnode_height="$(echo "$chia_show_fullnode" | grep Time | sed 's/.*Height://g' | sed 's/ //g')"
#chia_last_farmed_height="$(echo "$chia_farm_summary" | grep 'Last height farmed' | sed 's/.*farmed: //g')"
#blocks_since_win=`echo "scale=0; (${chia_fullnode_height} - ${chia_last_farmed_height})" | bc -l`
farm_plot_count="$(echo "$chia_farm_summary" | grep 'Plot count' | sed 's/.*count: //g')"
echo "# HELP farm_plot_count Number of Chia farm plots"
echo "# TYPE farm_plot_count counter"
echo "farm_plot_count" $farm_plot_count
farm_plots_size="$(echo "$chia_farm_summary" | grep 'Total size of plots' | sed 's/.*plots: //g' | sed 's/..iB//g')"
echo "# HELP farm_plots_size Total size of Chia farm plots"
echo "# TYPE farm_plots_size gauge"
echo "farm_plots_size" $farm_plots_size
# Politely deactivate the venv, I guess
deactivate
