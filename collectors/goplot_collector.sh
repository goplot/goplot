#!/bin/bash
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
# Echo the metrics to stdout
# When using in cron you can pipe the output to sponge, then redirect to the final destination in the textfile collector directory
echo "# HELP goplot_running_plots Number of currently running plots"
echo "# TYPE goplot_running_plots gauge"
echo "goplot_running_plots" $num_active_plots
on_toggle_file="${config_dir}/on_toggle.goplot"
if [ -f "$on_toggle_file" ]; then
on_toggle=$(tail -n1 "$on_toggle_file")
echo "# HELP goplot_config_ontoggle goplot on_toggle state"
echo "# TYPE goplot_config_ontoggle gauge"
echo "goplot_config_ontoggle" $on_toggle
fi
max_plots_file="${config_dir}/max_plots.goplot"
if [ -f "$on_toggle_file" ]; then
max_plots=$(tail -n1 "$max_plots_file")
echo "# HELP goplot_config_maxplots goplot configured maximum parallel plots"
echo "# TYPE goplot_config_maxplots gauge"
echo "goplot_config_maxplots" $goplot_config_maxplots
fi
load_max_file="${config_dir}/load_max.goplot"
if [ -f "$on_toggle_file" ]; then
load_max=$(tail -n1 "$load_max_file")
echo "# HELP goplot_config_loadmax goplot configured load_max"
echo "# TYPE goplot_config_loadmax gauge"
echo "goplot_config_loadmax" $load_max_file
fi
plot_poll_file="${config_dir}/plot_poll.goplot"
if [ -f "$on_toggle_file" ]; then
plot_poll=$(tail -n1 "$plot_poll_file")
echo "# HELP goplot_config_plotpoll goplot configured plot poll length"
echo "# TYPE goplot_config_plotpoll gauge"
echo "goplot_config_plotpoll" $plot_poll
fi
plot_gap_file="${config_dir}/plot_gap.goplot"
if [ -f "$on_toggle_file" ]; then
plot_gap=$(tail -n1 "$plot_gap_file")
echo "# HELP goplot_config_plot_gap goplot configured plot gap length"
echo "# TYPE goplot_config_plot_gap gauge"
echo "goplot_config_plot_gap" $plot_gap
fi