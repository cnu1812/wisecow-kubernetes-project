#!/usr/bin/env bash

set -u

LOGFILE="logs/sys_health.log"
mkdir -p "$(dirname "$LOGFILE")"

# --- User-configurable thresholds ---
CPU_THRESHOLD=80          # percent (single-process high CPU not considered here)
MEM_THRESHOLD=80          # percent used
DISK_THRESHOLD=90         # percent used on any filesystem
TOP_PROC_CPU_THRESHOLD=50 # percent CPU used by a single process => alert

REQUIRED_PROCS=() 

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

log() {
  echo "[$(timestamp)] $*" | tee -a "$LOGFILE"
}

# Check CPU overall usage (using top to get idle)
check_cpu() {
  # Get CPU idle from top, then used = 100 - idle
  cpu_idle=$(top -bn1 | awk -F'id,' '/Cpu\(s\)/{ split($1,parts,","); gsub(/.*: /,"",parts[1]); } { } END { }' 2>/dev/null)
  # Simpler: use mpstat if available otherwise parse top
  if command -v mpstat >/dev/null 2>&1; then
    idle=$(mpstat 1 1 | awk '/all/ {print 100 - $12}')
    cpu_used=$(printf "%.0f" "$idle")
  else
    # fallback parsing using top
    cpu_line=$(top -bn1 | grep -i "Cpu(s)")
   
    idle=$(echo "$cpu_line" | awk -F',' '{ for(i=1;i<=NF;i++){ if($i ~ /id/) {print $i} } }' | sed 's/[^0-9.]*//g')
    if [ -z "$idle" ]; then idle=100; fi
    cpu_used=$(awk "BEGIN {printf \"%d\", 100 - $idle}")
  fi

  if [ "$cpu_used" -ge "$CPU_THRESHOLD" ]; then
    log "ALERT: CPU usage high: ${cpu_used}% (threshold ${CPU_THRESHOLD}%)"
  else
    echo "[$(timestamp)] OK: CPU ${cpu_used}% (threshold ${CPU_THRESHOLD}%)" >> "$LOGFILE"
  fi
}

# Check memory usage
check_mem() {
  
  mem_used=$(free | awk '/Mem:/ {printf "%d", $3/$2*100}')
  if [ "$mem_used" -ge "$MEM_THRESHOLD" ]; then
    log "ALERT: Memory usage high: ${mem_used}% (threshold ${MEM_THRESHOLD}%)"
  else
    echo "[$(timestamp)] OK: Mem ${mem_used}% (threshold ${MEM_THRESHOLD}%)" >> "$LOGFILE"
  fi
}

# Check disk usage (check each mounted FS)
check_disk() {
  df -hP | awk 'NR>1 {print $5 " " $6}' | while read -r percent mount; do
    pct=${percent%\%}
    if [ "$pct" -ge "$DISK_THRESHOLD" ]; then
      log "ALERT: Disk usage high on ${mount}: ${pct}% (threshold ${DISK_THRESHOLD}%)"
    else
      echo "[$(timestamp)] OK: Disk ${mount} ${pct}% (threshold ${DISK_THRESHOLD}%)" >> "$LOGFILE"
    fi
  done
}

# Check for processes that are required to be running
check_required_procs() {
  for p in "${REQUIRED_PROCS[@]}"; do
    if pgrep -x "$p" >/dev/null 2>&1; then
      echo "[$(timestamp)] OK: Process $p is running" >> "$LOGFILE"
    else
      log "ALERT: Process $p is NOT running"
    fi
  done
}

# Check for single processes using huge CPU
check_top_cpu_procs() {

  ps -eo pid,pcpu,comm --sort=-pcpu | awk -v thr="$TOP_PROC_CPU_THRESHOLD" 'NR>1 && $2+0 > thr { printf "%s %s %s\n", strftime("%Y-%m-%d %H:%M:%S"), $1, $0 }' | while read -r line; do
    # format: timestamp pid pcpu comm...
    log "ALERT: High CPU process: $line"
  done
}

# --- Run checks ---
log "INFO: Starting system health check"
check_cpu
check_mem
check_disk
check_required_procs
check_top_cpu_procs
log "INFO: Completed system health check"
