#!/bin/bash
# Set the location of the Chia debug log, be sure to run as root or the same user that installed Chia
chia_log="/root/.chia/mainnet/log/debug.log"
# Set the directory for the Prometheus text collector
prom_collector_dir="/etc/prometheus/collectors"
# Set the name for the plots_eligible .prom file
harvester_status_prom_file="$prom_collector_dir/harvester_status.prom"
# Set the name for the plots_eligible .prom file
plots_eligible_prom_file="$prom_collector_dir/plots_eligible.prom"
# Set the name for the plots_eligible .prom file
proofs_prom_file="$prom_collector_dir/proofs.prom"
# Set the threshold in seconds for no eligible proofs entries that will result in the status metric to be set to 0
no_eligible_thresh=30
# Set SECONDS to 0
SECONDS=0
# Set last_eligible_secs to 0 for the first loop
last_eligible_secs=0
# Set the seconds to sleep after finding an entry for eligible proofs, no reason to keep working between proof checks
sleep_secs=7
# Set the default harvester status to 0 and send that to the prom file for the first loop
harvester_status=0
{ echo "# HELP farm harvester status Chia harvester status";
echo "# TYPE farm_harvester_status gauge";
echo "farm_harvester_status $harvester_status"; } > $harvester_status_prom_file
# Tail the log, use "-F" to keep on a new file after it rotates
tail -Fn0 $chia_log | \
while read line ; do
  # Set per-loop variables to nil at the start of each loop
  harvester_line=""
  plots_eligible=""
  proofs_found=""
  # Set the pause toggle to off at the start of each loop
  pause=0
  # Only keep and process the line if it is about the harvester
  harvester_line=$(echo "$line" | grep 'harvester' | tail -n1)
  if [[ ! -z $harvester_line ]] ; then
    now=$(echo "$SECONDS")
    echo "read a harvester line at $now seconds"
    # Get the time since the last eligible plots message showed
    time_since_last_eligible=$(( $now - $last_eligible_secs ))
    echo "it has been $time_since_last_eligible seconds since the last eligible proofs line was read"
    # If it has been longer than the threshold then set the new status to down
    if (( time_since_last_eligible > no_eligible_thresh )); then
      echo "this is longer than the threshold of $no_eligible_thresh so making the status down"
      new_harvester_status=0
    fi
    # Only set plots_eligible if the harvester log line contains the eligible plots text
    plots_eligible=$(echo "$harvester_line" | grep 'plots were eligible' | tail -n1 | sed 's/^.*INFO//g' | sed 's/plots were.*//g' | sed 's/ //g')
    # If plots_eligible is no longer nil then send the metric to the prom file
    if [[ ! -z $plots_eligible ]] ; then
      # Set the pause toggle to on
      pause=1
      # Set last_eligible_secs to this time
      last_eligible_secs=$(echo "$SECONDS")
      # Set the new status as up
      new_harvester_status=1
      echo "read a eligible_proof line, setting the status to up and last_eligible_secs to $last_eligible_secs"
      # Send the plots_eligible metric to the prom file
      { echo "# HELP plots eligible Chia harvester plots pass proof check filter";
      echo "# TYPE farm_harvester_plots_eligible gauge";
      echo "farm_harvester_plots_eligible $plots_eligible"; } > $plots_eligible_prom_file
    fi
    # If proofs_found is no longer nil then send the metric to the prom file
    proofs_found=$(echo "$line" | grep "proof" | grep -v Duplicate | tail -n1 | sed 's/^.*Found//g' | sed 's/proofs.*//g' | sed 's/ //g')
    if [[ ! -z $proofs_found ]] ; then
      { echo "# HELP proofs found Chia harvester proofs found";
        echo "# TYPE farm_harvester_proofs_found gauge";
        echo "farm_harvester_proofs_found $proofs_found"; } > $proofs_prom_file
    fi
    # If the harvester status has changed then save it and send it to the prom file
    if (( new_harvester_status != harvester_status )) ; then
      echo "the status has changed from $harvester_status to $new_harvester_status, setting the status metric to $new_harvester_status"
      harvester_status=$new_harvester_status
      { echo "# HELP farm harvester status Chia harvester status";
      echo "# TYPE farm_harvester_status gauge";
      echo "farm_harvester_status $harvester_status"; } > $harvester_status_prom_file
    fi
  fi
  if [[ $pause = 1 ]] ; then
    sleep $sleep_secs
  fi
done
