#!/bin/bash
promfile="/etc/prometheus/collectors/goplotstats.prom"
value_num_active_plots="$(ps -eaf | grep 'chia plots create' | grep -v 'grep' -c)"
echo "# HELP goplot_running_plots Number of currently running plots"
echo "# TYPE goplot_running_plots gauge"
echo "goplot_running_plots" $value_num_active_plots
on_toggle_file="${config_dir}/on_toggle.goplot"
on_toggle=$(tail -n1 "$on_toggle_file")
echo "# HELP goplot_config_ontoggle goplot on_toggle state"
echo "# TYPE goplot_config_ontoggle gauge"
echo "goplot_config_ontoggle" $on_toggle
max_plots_file="${config_dir}/max_plots.goplot"
max_plots=$(tail -n1 "$max_plots_file")
echo "# HELP goplot_config_maxplots goplot configured maximum parallel plots"
echo "# TYPE goplot_config_maxplots gauge"
echo "goplot_config_maxplots" $goplot_config_maxplots
load_max_file="${config_dir}/load_max.goplot"
load_max=$(tail -n1 "$load_max_file")
echo "# HELP goplot_config_loadmax goplot configured load_max"
echo "# TYPE goplot_config_loadmax gauge"
echo "goplot_config_loadmax" $load_max_file
plot_poll_file="${config_dir}/plot_poll.goplot"
plot_poll=$(tail -n1 "$plot_poll_file")
echo "# HELP goplot_config_plotpoll goplot configured plot poll length"
echo "# TYPE goplot_config_plotpoll gauge"
echo "goplot_config_plotpoll" $plot_poll
plot_gap_file="${config_dir}/plot_gap.goplot"
plot_gap=$(tail -n1 "$plot_gap_file")
echo "# HELP goplot_config_plot_gap goplot configured plot gap tength"
echo "# TYPE goplot_config_plot_gap gauge"
echo "goplot_config_plot_gap" $plot_gap
