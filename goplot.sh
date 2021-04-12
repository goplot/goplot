#!/bin/bash
# Enter your Grafana API key here enclosed in single quotes
# The API key can be created in your Grafana portal at http://localhost:3000/org/apikeys
grafana_api_key='myAPIkey'
# This is the annotations URL on the localhost, change if this script is not being run on the Grafana host
grafana_url="http://localhost:3000/api/annotations/graphite"
# Set the working directory for the script
working_dir="/etc/chia/goplot"
# Set the location for the log file
main_log="${working_dir}/logs/goplot.log"
# Set the directory where the config and state files are kept
config_dir="${working_dir}/config"
# Log starting of the script for posterity's sake
echo "$(date) - goplot   : start goplot.sh" >> $main_log
# Default the on_toggle to 'no'
on_toggle="no"
# Set on_toggle for the first time through with the actual value from the config file
on_toggle_file="${config_dir}/on_toggle.goplot"
# Only continue if the on_toggle file exists, otherwise set it to 'no' so the script will exit
if [ -f "$on_toggle_file" ]; then
	on_toggle=$(tail -n1 "$on_toggle_file")
	if [[ $on_toggle != "run" ]]; then
		echo "$(date) - goplot   : on_toggle file is not set to 'run', the script will not run" >> $main_log
	fi
else
	on_toggle="no"
	echo "$(date) - goplot   : on_toggle file not found, stopping script" >> $main_log
fi
# Set SECONDS to 0
SECONDS=0
# Main loop, requires the on_toggle to be set to 'run' or the script will not run
while [[ $on_toggle == "run" ]]; do
    # Read the on_toggle file every time the loop starts so the script can be stopped gracefully
	on_toggle=$(tail -n1 "$on_toggle_file")
    # Get the current system load using uptime
	load=( $(uptime | sed 's/.*average: //g' | sed 's/,//g') )
    # Set the 5 min and 15 min load values
	min5_load=${load[1]}
	min15_load=${load[2]}
    # Average the 5 min and 15 min values, this seems to be a better load indicator for plotting purposes than using either one
	load_avg=`echo "scale=2; (${min5_load} + ${min15_load}) / 2" | bc -l`
    # Get the number of currently active plots using ps
	num_active_plots="$(ps -eaf | grep 'chia plots create' | grep -v 'grep' -c)"
	echo "$(date) - goplot   :" $num_active_plots "plots currently plotting" >> $main_log
	# Set the number of seconds between each poll for a plot start, using the config file
	plot_poll_file="${config_dir}/plot_poll.goplot"
    # If the file does not exist then set the value to a safe default and the on_toggle to 'no'
	if [ -f "$plot_poll_file" ]; then
		plot_poll=$(tail -n1 "$plot_poll_file")
	else
        # Safe default
		plot_poll=30
		on_toggle="no"
		echo "$(date) - goplot   : plot_poll file not found, on_toggle set to 'no'"
	fi
	echo "$(date) - goplot   : waiting" $plot_poll "seconds between each condition check" >> $main_log
    # Gotta check that file again here
	on_toggle=$(tail -n1 "$on_toggle_file")
    # Set the minimum number of seconds between each plot, using the config file
	plot_gap_file="${config_dir}/plot_gap.goplot"
	if [ -f "$plot_gap_file" ]; then
		plot_gap=$(tail -n1 "$plot_gap_file")
	else
        # Safe default
		plot_gap=1800
		on_toggle="no"
		echo "$(date) - goplot   : plot_gap file not found, on_toggle set to 'no'" >> $main_log
	fi
	echo "$(date) - goplot   : minimum time between plots:" $plot_gap "" >> $main_log
    # Set the maximum number of parallel plots that should run, using the config file
	max_plots_file="${config_dir}/max_plots.goplot"
	if [ -f "$max_plots_file" ]; then
		max_plots=$(tail -n1 "$max_plots_file")
		echo "$(date) - goplot   : max_plots set to:" $max_plots "" >> $main_log
	else
        # Safe default
		max_plots=1
		echo "$(date) - goplot   : max_plots file not found; setting to 1" >> $main_log
	fi
    # Set the load threshold above which new plots will not be started, using the config file
	load_max_file="${config_dir}/load_max.goplot"
	if [ -f "$load_max_file" ]; then
		load_max=$(tail -n1 "$load_max_file")
		echo "$(date) - goplot   : load_max set to:" $load_max "" >> $main_log
	else
        # Safe default
		load_max=26
		echo "$(date) - goplot   : load_max file not found; setting to 26" >> $main_log
	fi
    # Set the plot_start toggle to 'no'
	plot_start="no"
	# Check for the requirements to start a new plot before moving on, if not met then sleep for the poll period
	while [[ $on_toggle == "run" ]] && [[ $plot_start == "no" ]]; do
		on_toggle=$(tail -n1 "$on_toggle_file")
		if [[ $on_toggle != "run" ]]; then
			echo "$(date) - goplot   : on_toggle file is not set to 'run', the script will not run" >> $main_log
			on_toggle="no"
		fi
        # We need to check the load on every requirements check
		load=( $(uptime | sed 's/.*average: //g' | sed 's/,//g') )
		min5_load=${load[1]}
		min15_load=${load[2]}
		load_avg=`echo "scale=2; (${min5_load} + ${min15_load}) / 2" | bc -l`
        # We need to check the number of active plots again
		num_active_plots="$(ps -eaf | grep 'chia plots create' | grep -v 'grep' -c)"
        # If the current load is too high or the number of maximum plots has been reached then sleep for the poll period before checking requirements again
		if (( $(echo "$load_avg > $load_max" | bc -l) )) || (( num_active_plots >= max_plots )); then
			echo "$(date) - goplot   : plot not started;" $num_active_plots"/"$max_plots "plots plotting with load" $load_avg"/"$load_max >> $main_log
			sleep $plot_poll
		else
			# Once the requirements are met then launch tractor.sh to start a new plot
			echo "$(date) - goplot   : currently" $num_active_plots"/"$max_plots "plots plotting with load" $load_avg"/"$load_max >> $main_log
			echo "$(date) - goplot   : starting tractor.sh to run a new plot" >> $main_log
			. $working_dir/tractor.sh &
            # Set plot_start to 'yes' to pop out of the loop
			plot_start="yes"
            # Insert a pause here so that the log entries from the tractor can finish before adding the plot gap sleep entry
			sleep 15
			echo "$(date) - goplot   : sleeping for" $plot_gap "seconds before the next plot check" >> $main_log
		fi
	done
    # Sleep for the minimum time set between plots
	sleep $plot_gap
done
echo "$(date) - goplot   : goplot.sh ended after " $SECONDS "seconds" >> $main_log