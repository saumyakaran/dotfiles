#!/bin/sh

PAGESIZE=$(sysctl -n hw.pagesize)
MEM_TOTAL=$(sysctl -n hw.memsize)

# App Memory + Wired + Compressed = "Memory Used" (matches Activity Monitor)
PAGES_ACTIVE=$(vm_stat | awk '/Pages active/ {gsub(/\./, "", $3); print $3}')
PAGES_WIRED=$(vm_stat | awk '/Pages wired/ {gsub(/\./, "", $4); print $4}')
PAGES_COMPRESSED=$(vm_stat | awk '/Pages occupied by compressor/ {gsub(/\./, "", $5); print $5}')

USED_BYTES=$(( (PAGES_ACTIVE + PAGES_WIRED + PAGES_COMPRESSED) * PAGESIZE ))
USED_GB=$(echo "scale=1; $USED_BYTES / 1073741824" | bc)
TOTAL_GB=$(echo "scale=0; $MEM_TOTAL / 1073741824" | bc)

sketchybar --set $NAME label="${USED_GB}/${TOTAL_GB}G"
