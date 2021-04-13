#!/bin/bash
# Set the working directory for the script
working_dir="/etc/chia/goplot"
# Set the directory where the config and state files are kept
config_dir="${working_dir}/config"
# Set the directory where the disk state files are kept
disk_dir="${working_dir}/disks"
# Set the log location
log="${working_dir}/logs/diskhand.log"
# Set the final plot size in bytes, best to round up to the nearest GiB here
final_plot_size=102000000
# Put in a slop number, this is just to be sure that we don't try to use a disk that does not have enough space
slop=4000000
# Add the slop to the final plot size to determin the needed size
need_space=$(( final_plot_size + slop ))
echo "$(date) - diskhand : start diskhand.sh" > $log
# Set the path to the farm
farms_path="/farm"
# Get the farms under the farm path
farms=(`ls ${farms_path}`)
echo "$(date) - diskhand : farms found:" ${farms[@]} >> $log
# For each farm get the disks
for farm in ${farms[@]}; do
	farm_path="/farm/${farm}"
	disks=(`ls ${farm_path}`)
    # Check the available space for each disk, but only if the disk file has not already been set > 9999999999999
	for disk in ${disks[@]}; do
		disk_path="${farm_path}/${disk}"
		disk_file="${disk_dir}/${disk}.goplot"
		file_size=$(tail -n1 "$disk_file")
		if (( file_size < 9999999999999 )); then
			echo "$(date) - diskhand : checking space available on" $disk_path  >> $log
			disk_df_used=(`df | grep ${disk_path} | awk '{print \$3}'`)
			disk_df_avail=(`df | grep ${disk_path} | awk '{print \$4}'`)
			disk_df_total=$(( disk_df_used + disk_df_avail ))
			echo "$(date) - diskhand :" $disk_path $disk_df_used"/"$disk_df_total"/"$disk_df_avail "used/total/available" >> $log
			disk_plots_committed="$(ps -eaf | grep 'chia plots create' | grep -v 'grep' | grep ${disk} -c)"
			disk_committed=$(( disk_plots_committed * final_plot_size ))
			echo "$(date) - diskhand :" $disk_path "has" $disk_committed "space committed" >> $log
			disk_total_used=$(( disk_df_used + disk_committed ))
			disk_left=$(( disk_df_total - disk_total_used ))
			echo "$(date) - diskhand :" $disk_path "has" $disk_left "space available for plotting" >> $log
            # If the disk has room set the disk file to the actual size, if not then set the size to 9999999999999
			if (( disk_left < need_space )); then
				echo "$(date) - diskhand :" $disk_path "does not have room for plotting, setting size to 99999999999999" >> $log
				disk_used=99999999999999
			else
				echo "$(date) - diskhand :" $disk_path "has room for plotting, setting size to" $disk_total_used >> $log
				disk_used=$disk_total_used
			fi
			echo $disk_used > $disk_file
		else
			echo "$(date) - diskhand :" $disk_file "is set to" $file_size"; not using" $disk >> $log
		fi
	done
done
echo "$(date) - diskhand : finished diskhand.sh" >> $log