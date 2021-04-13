#!/bin/bash
# Enter your Grafana API key enclosed in single quotes
# The API key can be created in your Grafana portal at http://localhost:3000/org/apikeys
grafana_api_key='myAPIkey'
# Set the annotations URL on the localhost, change if this script is not being run on the Grafana host
grafana_url="http://localhost:3000/api/annotations/graphite"
# Set SECONDS to 0
SECONDS=0
# Set the working directory for the script
working_dir="/etc/chia/goplot"
# Set the directory where the config and state files are kept
config_dir="${working_dir}/config"
# Set the directory where the disk state files are kept
disk_dir="${working_dir}/disks"
# Set the location of the chia virtual environment
chia_venv_dir="/etc/chia/chia-blockchain"
# Use the same log as goplot.sh
main_log="${working_dir}/logs/goplot.log"
echo "$(date) - prejob   : tractor.sh started" >> $main_log
# Check the on_toggle
on_toggle_file="${config_dir}/on_toggle.goplot"
# Only start a plot if the on_toggle file exists and is set to 'run'
if [ -f "$on_toggle_file" ]; then
	on_toggle=$(tail -n1 "$on_toggle_file")
	if [[ $on_toggle != "run" ]]; then
		echo "$(date) - prejob   : on_toggle file is not set to 'run', the script will not run" >> $main_log
	else
        # Set the buffers
		buffer=4000
        # Set the buckets
		buckets=128
        # Set the number of threads to use
		threads=2
        # Set the plot size
		k=32
		# Set the bitfield flag, either "-e" to turn bitfield off, or "" to leave it on
		bitfield=""
        # Get the last destination farm used from the farm state file
		dest_farm_file="${config_dir}/farm_dest.goplot"
		last_dest_farm=$(tail -n1 "$dest_farm_file")
        # Set the destination farm path
        dest_farms_path="/farm"
        # Find the destination farms, put them in a list
        dest_farms=(`ls ${dest_farms_path}`)
        echo "$(date) - prejob   : destination farms found:" ${dest_farms[@]} >> $main_log
        # Set the number of destination farms found
        num_dest_farms=$(echo ${dest_farms[@]})
        # Set the destination farm to use on this plot, just increment the last farm by 1
        my_dest_farm=(( last_dest_farm + 1 ))
        # If the farm number is greater than the farms available then set the plot to use farm 1
		if (( my_dest_farm > num_dest_farms )); then
			my_dest_farm=1
		fi
        # Get the last temp farm used from the farm state file
		temp_farm_file="${config_dir}/farm_temp.goplot"
		last_temp_farm=$(tail -n1 "$dest_farm_file")
        # Set the plot temp drive path
        temp_farms_path="/plot_temp"
        # Find the temp farms, put them in a list
        temp_farms=(`ls ${temp_farms_path}`)
        echo "$(date) - prejob   : temp farms found:" ${temp_farms[@]} >> $main_log
        # Set the number of destination farms found
        num_temp_farms=$(echo ${temp_farms[@]})
        # Set the temp farm to use on this plot, just increment the last farm by 1
        my_temp_farm=(( last_temp_farm + 1 ))
        # If the farm number is greater than the farms available then set the plot to use farm 1
		if (( my_temp_farm > num_temp_farms )); then
			my_temp_farm=1
		fi
        # Set the plot temp path
		plots_temp_path="/plot_temp/${my_temp_farm}"
        # Set the plot temp 2 path
		plots_t2_path="/plot_temp/${my_temp_farm}"
        # Set the plot destination farm number
		plots_farm_path="/farm/${my_dest_farm}"
        # Get the farm disks
		disks=(`ls ${plots_farm_path}`)
        # Set the default size to a high number
		size=999999999999
        # Compare each destination disk file (created by diskhand.sh) to the size and determine if the disk should be used for the plot
        # This results in destination disks being filled from the bottom up in relation to each other
		for disk in ${disks[@]}; do
			new_size=$(tail -n1 "$disk_dir/${disk}.goplot")
			if (( new_size < size )); then
				if [ -d "${plots_farm_path}/${disk}/plots" ] && [ -d "${plots_farm_path}/${disk}/logs" ]; then
					size=$new_size
					my_disk=${disk}
				else
					echo "$(date) - prejob   : WARNING - directories have not been created on ${plots_farm_path}/${disk}"
				fi
			fi
		done
		# If the size has not changed then there must not be room for plotting on any disks, send an error to the log
		if (( size == "999999999999" )); then
			echo "$(date) - prejob   : WARNING - No disk space available for plotting on destination /farm/${my_dest_farm}" >> $main_log
		else
			# Set the location of the goplot index number
			index_file="${config_dir}/index.goplot"
			# Set the number of the last plot to the value in the index file
			last_plot=$(tail -n1 "$index_file")
			# Increment the last plot number by one to get this plot number
			my_plot_num=$(( last_plot + 1 ))
			# Get the number of active plots for logging purposes
			num_active_plots="$(ps -eaf | grep 'chia plots create' | grep -v 'grep' -c)"
			# Increment the number of active plots by one to get this plot run
			my_run=$(( num_active_plots + 1 ))
			# Set the plot destination based on the disk selected earlier
			plots_dest_path="/farm/${my_dest_farm}/${my_disk}/plots"
			# Output the log to a dir on the same disk
			plots_log_path="/farm/${my_dest_farm}/${my_disk}/logs"
			# Set the log file name based on plot number
			plot_log_name="plot.${my_plot_num}.log"
			my_plot_log="${plots_log_path}/${plot_log_name}"
			# Log all these details
			echo "$(date) - prejob   : plot-"$my_plot_num "temp path:" $plots_temp_path >> $main_log
			echo "$(date) - prejob   : plot-"$my_plot_num "t2 path:" $plots_t2_path >> $main_log
			echo "$(date) - prejob   : plot-"$my_plot_num "plot destination:" $plots_dest_path >> $main_log
			echo "$(date) - prejob   : plot-"$my_plot_num "my_plot_log:" $my_plot_log >> $main_log
			echo "$(date) - strtplot : plot-"$my_plot_num "time to plot!" >> $main_log
			echo "$(date) - strtplot : plot-"$my_plot_num "incrementing index.goplot to" $my_plot_num >> $main_log
			# Update the index file with the current plot number
			echo $my_plot_num > $index_file
			echo "$(date) - strtplot : plot-"$my_plot_num "updating farm_dest.goplot to" $my_dest_farm >> $main_log
			# Update the destination farm file with the current farm number
			echo $my_dest_farm > $dest_farm_file
			echo "$(date) - strtplot : plot-"$my_plot_num "updating farm_temp.goplot to" $my_temp_farm >> $main_log
			# Update the destination farm file with the current farm number
			echo $my_temp_farm > $temp_farm_file
			# Change to the chia directory and activate the venv
			cd $chia_venv_dir
			echo "$(date) - strtplot : plot-"$my_plot_num "activating the chia-blockchain venv" >> $main_log
			. ./activate
			# Send a plot_start annotation to Grafana
			gr_what=`echo '"start plot #'${my_plot_num}'"'`
			gr_tags='["plot_start"]'
			gr_data=`echo '"'${my_run}'/'${max_plots} 'active"'`
			gr_body=`echo '{"what":'${gr_what}',"tags":'${gr_tags}',"data":'${gr_data}'}'`
			curl -H "Authorization: Bearer ${grafana_api_key}" -H "Content-Type: application/json" -d "${gr_body}" -X POST $grafana_url
			echo "$(date) - strtplot : plot-"$my_plot_num "starting run" $my_run"/"$max_plots "with cmd: chia plots create -k ${k} -r ${threads} -n 1 -b ${buffer} -u ${buckets} ${bitfield} -t ${plots_temp_path} -2 ${plots_t2_path} -d ${plots_dest_path}" >> $main_log
			# Start the plot!
			chia plots create -k ${k} -r ${threads} -n 1 -b ${buffer} -u ${buckets} ${bitfield} -t ${plots_temp_path} -2 ${plots_t2_path} -d ${plots_dest_path} >> $my_plot_log
			echo "$(date) - endplot  : plot-"$my_plot_num "ended, total time:" $SECONDS >> $main_log
			# Send a plot_end annotation to Grafana
			gr_what=`echo '"end plot #'${my_plot_num}'"'`
			gr_tags='["plot_end"]'
			gr_data=`echo '"total time:' ${SECONDS}'"'`
			gr_body=`echo '{"what":'${gr_what}',"tags":'${gr_tags}',"data":'${gr_data}'}'`
			curl -H "Authorization: Bearer ${grafana_api_key}" -H "Content-Type: application/json" -d "${gr_body}" -X POST $grafana_url
			# Politely deactivate the chia venv
			deactivate
		fi
	fi
else
    # Don't start the plot if the on_toggle is not set to run
	on_toggle="no"
	echo "$(date) - prejob   : on_toggle file not found, stopping script" >> $main_log
fi