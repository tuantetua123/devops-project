#!/usr/bin/env bash
# Server health check. Prints one JSON line; exits 1 if any threshold is exceeded.
# Env: DISK_MAX (percent, default 85), MEM_MIN_MB (default 200), LOAD_MAX_PER_CPU (default 2)
set -uo pipefail

DISK_MAX="${DISK_MAX:-85}"
MEM_MIN_MB="${MEM_MIN_MB:-200}"
LOAD_MAX_PER_CPU="${LOAD_MAX_PER_CPU:-2}"
problems=()

disk="$(df --output=pcent / | tail -1 | tr -dc '0-9')"
mem_mb="$(awk '/^MemAvailable:/ {printf "%d", $2/1024}' /proc/meminfo)"
load1="$(cut -d' ' -f1 /proc/loadavg)"
cpus="$(nproc)"
unhealthy=0

[ "$disk" -ge "$DISK_MAX" ] && problems+=("disk ${disk}% used")
[ "$mem_mb" -le "$MEM_MIN_MB" ] && problems+=("only ${mem_mb}MB memory available")
awk -v l="$load1" -v c="$cpus" -v m="$LOAD_MAX_PER_CPU" 'BEGIN{exit !(l > c*m)}' && problems+=("load ${load1} on ${cpus} cpu")

if command -v docker > /dev/null 2>&1; then
  if docker info > /dev/null 2>&1; then
    unhealthy="$(docker ps --filter health=unhealthy -q | wc -l | tr -d ' ')"
    [ "$unhealthy" -gt 0 ] && problems+=("${unhealthy} unhealthy container(s)")
  else
    problems+=("docker daemon unreachable")
  fi
fi

if [ "${#problems[@]}" -eq 0 ]; then
  status=ok
  detail=""
else
  status=fail
  detail="$(IFS=';'; echo "${problems[*]}")"
fi

printf '{"ts":"%s","status":"%s","disk_pct":%s,"mem_available_mb":%s,"load1":%s,"cpus":%s,"unhealthy_containers":%s,"problems":"%s"}\n' \
  "$(date -u +%FT%TZ)" "$status" "$disk" "$mem_mb" "$load1" "$cpus" "$unhealthy" "$detail"

[ "$status" = ok ]