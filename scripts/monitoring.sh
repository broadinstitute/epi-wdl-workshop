#!/bin/bash

# This script is autorun from within each container
# to monitor its usage of CPU/mem/disk.
#
# The results should be stored to monitoring.log
# in the task call's folder.

mem() {
  grep ^Mem$1 /proc/meminfo | awk '{ print $2 }'
}

mem_used() {
  printf $(( 100 * ($(mem Total) - $(mem Available)) / $(mem Total) ))
}

PREV_TOTAL=0
PREV_IDLE=0

cpu_used() {
  # https://github.com/pcolby/scripts/blob/master/cpu.sh

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
  printf $DIFF_USAGE

  # Remember the total and idle CPU times for the next check.
  PREV_TOTAL="$TOTAL"
  PREV_IDLE="$IDLE"
}

disk_used() {
  printf $(df -h | grep cromwell_root | awk '{ print $3 }')
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
  cpu_used
  printf '\t'
  mem_used
  printf '\t'
  disk_used
  printf '\t'
  date
}
while true; do runtimeInfo 2>/dev/null; sleep 10; done
