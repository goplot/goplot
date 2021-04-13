#!/bin/bash
# 
chia_log="/root/.chia/mainnet/log/debug.log"
prom_collector_dir="/etc/prometheus/collectors"
plots_eligible_prom_file="$prom_collector_dir/plots_eligible.prom"
proofs_prom_file="$prom_collector_dir/proofs.prom"
block_prom_file="$prom_collector_dir/block_won.prom"
SECONDS=0
sleep_secs=7
tail -Fn0 $chia_log | \
while read line ; do
  plots_eligible=""
  proofs_found=""
  pause=0
  plots_eligible=$(echo "$line" | grep 'plots were eligible' | tail -n1 | sed 's/^.*INFO//g' | sed 's/plots were.*//g' | sed 's/ //g')
  if [[ ! -z $plots_eligible ]] ; then
    pause=1
    last_eligible_secs=$SECONDS
    { echo "# HELP plots eligible Chia harvester plots pass proof check filter";
    echo "# TYPE farm_harvester_plots_eligible gauge";
    echo "farm_harvester_plots_eligible $plots_eligible";
    echo "# HELP farm harvester status Chia harvester status";
    echo "# TYPE farm_harvester_status gauge";
    echo "farm_harvester_status 1"; } > $plots_eligible_prom_file
  fi
  proofs_found=$(echo "$line" | grep "proof" | grep -v Duplicate | tail -n1 | sed 's/^.*Found//g' | sed 's/proofs.*//g' | sed 's/ //g')
  if [[ ! -z $proofs_found ]] ; then
    { echo "# HELP proofs found Chia harvester proofs found";
      echo "# TYPE farm_harvester_proofs_found gauge";
      echo "farm_harvester_proofs_found $proofs_found"; } > $proofs_prom_file
  fi
  if [[ $pause = 1 ]] ; then
    sleep $sleep_secs
  fi
done