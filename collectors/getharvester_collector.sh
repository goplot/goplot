#!/bin/bash
chia_venv_dir="/etc/chia/chia-blockchain"
cd $chia_venv_dir
. ./activate
chia_farm_summary="`chia farm summary`"
farm_plot_count="$(echo "$chia_farm_summary" | grep 'Plot count' | sed 's/.*count: //g')"
echo "# HELP farm_plot_count Number of Chia farm plots"
echo "# TYPE farm_plot_count counter"
echo "farm_plot_count" $farm_plot_count
farm_plots_size="$(echo "$chia_farm_summary" | grep 'Total size of plots' | sed 's/.*plots: //g' | sed 's/..iB//g')"
echo "# HELP farm_plots_size Total size of Chia farm plots"
echo "# TYPE farm_plots_size gauge"
echo "farm_plots_size" $farm_plots_size
deactivate
