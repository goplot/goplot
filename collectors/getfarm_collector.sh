#!/bin/bash
chia_venv_dir="/etc/chia/chia-blockchain"
cd $chia_venv_dir
. ./activate
chia_show_fullnode="`chia show -s`"
chia_fullnode_syncstatus="$(echo "$chia_show_fullnode" | grep 'Current Blockchain Status' | sed 's/.*Status: //g')"
if [[ $chia_fullnode_syncstatus == "Full Node Synced" ]]; then
	    farm_fullnode_syncstatus=1
    else
	        farm_fullnode_syncstatus=0
fi
echo "# HELP farm_fullnode_syncstatus Chia full node sync status"
echo "# TYPE farm_fullnode_syncstatus gauge"
echo "farm_fullnode_syncstatus" $farm_fullnode_syncstatus
chia_farm_summary="`chia farm summary`"
chia_farming_status="$(echo "$chia_farm_summary" | grep 'Farming status' | sed 's/.*status: //g')"
if [[ $chia_farming_status == "Farming" ]]; then
	    farm_farmer_farmstatus=1
    else
	        farm_farmer_farmstatus=0
fi
echo "# HELP farm_farmer_farmstatus Chia farmer farming status"
echo "# TYPE farm_farmer_farmstatus gauge"
echo "farm_farmer_farmstatus" $farm_farmer_farmstatus
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
deactivate
