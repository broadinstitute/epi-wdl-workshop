#!/bin/bash

# This script is autorun from within each container
# to monitor its usage of CPU/mem/disk.
#
# The results should be stored to monitoring.log
# in the task call's folder.

mem() {
  grep ^$1 /proc/meminfo | awk '{ print $2 }'
}

mem_total() {
  mem MemTotal
}

mem_used() {
  echo $(( $(mem_total) - $(mem MemAvailable) ))
}

cpu_used() {
  # from https://github.com/Leo-G/DevopsWiki/wiki/How-Linux-CPU-Usage-Time-and-Percentage-is-calculated
  # by Paul Colby (http://colby.id.au), no rights reserved ;)

  # Get the total CPU statistics, discarding the 'cpu ' prefix.
  CPU=(`sed -n 's/^cpu\s//p' /proc/stat`)
  IDLE=${CPU[3]} # Just the idle CPU time.

  # Calculate the total CPU time.
  TOTAL=0
  for VALUE in "${CPU[@]}"; do
    let "TOTAL=$TOTAL+$VALUE"
  done

  # Calculate the CPU usage since we last checked.
  let "DIFF_IDLE=$IDLE-$PREV_IDLE"
  let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
  let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"
  echo $DIFF_USAGE

  # Remember the total and idle CPU times for the next check.
  PREV_TOTAL="$TOTAL"
  PREV_IDLE="$IDLE"
}

echo ==================================
echo =========== MONITORING ===========
echo ==================================
echo --- General Information ---
(
  echo \#CPU: $(grep -c ^processor /proc/cpuinfo)
  echo Total Memory: $(mem_total | awk '{ printf "%.1fG", $1 / (1024 * 1024) }')
  echo Total Disk space: $(df -h | grep cromwell_root | awk '{ print $2 }')
) 2>/dev/null
echo
echo --- Runtime Information ---
echo -e "CPU,%\tMem,%\tDisk\tDate"
runtimeInfo() {
  local cpu=$(cpu_used)
  local mem=$(( ($(mem_used) * 100) / $(mem_total) ))
  local disk=$(df -h | grep cromwell_root | awk '{ print $3 }')

  echo -e "${cpu}\t${mem}\t${disk}\t$(date)"
}
while true; do runtimeInfo 2>/dev/null; sleep 10; done
