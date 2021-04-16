#!/bin/bash
# Script to quickly print the goplot configuration from CLI
# Set the goplot working directory
working_dir="/etc/chia/goplot"
# Set the directory where the config and state files are kept
config_dir="${working_dir}/config"
# Get the number of currently active plots
num_active_plots="$(ps -eaf | grep 'chia plots create' | grep -v 'grep' -c)"
# If the variable is empty set to 0
if [[ -z $num_active_plots ]]; then
num_active_plots=0
fi
# Echo the configuration variables from the files
echo "goplot_running_plots" $num_active_plots
on_toggle_file="${config_dir}/on_toggle.goplot"
if [ -f "$on_toggle_file" ]; then
on_toggle=$(tail -n1 "$on_toggle_file")
echo "on_toggle.goplot:" $on_toggle
else
echo "on_toggle.goplot does not exist"
fi
max_plots_file="${config_dir}/max_plots.goplot"
if [ -f "$max_plots_file" ]; then
max_plots=$(tail -n1 "$max_plots_file")
echo "max_plots.goplot:" $max_plots
else
echo "max_plots.goplot does not exist"
fi
load_max_file="${config_dir}/load_max.goplot"
if [ -f "$load_max_file" ]; then
load_max=$(tail -n1 "$load_max_file")
echo "load_max.goplot:" $load_max
else
echo "load_max.goplot does not exist"
fi
plot_poll_file="${config_dir}/plot_poll.goplot"
if [ -f "$plot_poll_file" ]; then
plot_poll=$(tail -n1 "$plot_poll_file")
echo "plot_poll.goplot:" $plot_poll
else
echo "plot_poll.goplot does not exist"
fi
plot_gap_file="${config_dir}/plot_gap.goplot"
if [ -f "$plot_gap_file" ]; then
plot_gap=$(tail -n1 "$plot_gap_file")
echo "plot_gap.goplot" $plot_gap
else
echo "plot_gap.goplot does not exist"
fi
