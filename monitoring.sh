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
  local cpu=$(top -bn 1 | grep -i cpu | grep -o [0-9]* | head -1)
  local mem=$(( ($(mem_used) * 100) / $(mem_total) ))
  local disk=$(df -h | grep cromwell_root | awk '{ print $3 }')

  echo -e "${cpu}\t${mem}\t${disk}\t$(date)"
}
while true; do runtimeInfo 2>/dev/null; sleep 10; done
