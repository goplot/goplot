#!/bin/bash
chia_venv_dir="/etc/chia/chia-blockchain"
cd $chia_venv_dir
. ./activate
chia_show_fullnode="`chia show -s`"
chia_fullnode_sync_status="$(echo "$chia_show_fullnode" | grep 'Current Blockchain Status' | sed 's/.*Status: //g')"
if [[ $chia_fullnode_sync_status == "Full Node Synced" ]]; then
    echo "Full node is synced!"
else
    echo "Full Node is not synced, farming is not possible"
fi
sleep 1
chia_farm_summary="`chia farm summary`"
chia_farming_status="$(echo "$chia_farm_summary" | grep 'Farming status' | sed 's/.*status: //g')"
if [[ $chia_farming_status == "Farming" ]]; then
    echo "Farmer is farming!"
else
    echo "The Farmer is NOT farming"
fi
sleep 2
echo ""
chia_fullnode_netspace="$(echo "$chia_show_fullnode" | grep 'Estimated network space' | sed 's/.*space: //g' | sed 's/ .*iB//g')"
echo "Estimated network space (Pib): $chia_fullnode_netspace"
chia_fullnode_difficulty="$(echo "$chia_show_fullnode" | grep 'Current difficulty' | sed 's/.*difficulty: //g')"
echo "Current difficulty: $chia_fullnode_difficulty"
chia_farmed="$(echo "$chia_farm_summary" | grep 'Total chia farmed' | sed 's/.*farmed: //g')"
echo "Total chia farmed: $chia_farmed"
chia_fullnode_height="$(echo "$chia_show_fullnode" | grep Time | sed 's/.*Height://g' | sed 's/ //g')"
chia_last_farmed_height="$(echo "$chia_farm_summary" | grep 'Last height farmed' | sed 's/.*farmed: //g')"
blocks_since_win=`echo "scale=0; (${chia_fullnode_height} - ${chia_last_farmed_height})" | bc -l`
echo "Blocks since last win: $blocks_since_win"
chia_plot_count="$(echo "$chia_farm_summary" | grep 'Plot count' | sed 's/.*count: //g')"
echo "Plot count (this farmer): $chia_plot_count"
chia_plots_size="$(echo "$chia_farm_summary" | grep 'Total size of plots' | sed 's/.*plots: //g')"
echo "Plots size (this farmer): $chia_plots_size"
sleep 5
chia_n2000_logs="`tail -n2000 ~/.chia/mainnet/log/debug.log`"
echo ""
echo "          --------  Last several log lines of harvester signage points  --------"
echo ""
echo "$chia_n2000_logs" | grep harvester | grep new_signage_point | tail -n8
sleep 5
echo ""
echo "          --------  Last several log lines of farmer proof checks  --------"
echo ""
echo "$chia_n2000_logs" | grep proofs | tail -n5
deactivate