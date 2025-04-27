#!/usr/bin/env bash

HOSTS_FILE="/etc/hosts"
SITE_LIST="${2:-$HOME/.digital_wellbeing/blocked_sites.txt}"

if [ ! -f "$SITE_LIST" ] || [ ! -s "$SITE_LIST" ]; then
  echo "Error: no block list found at $SITE_LIST"
  exit 1
fi

mapfile -t SITES < <(grep -E -v '^\s*($|#)' "$SITE_LIST")

generate_entries() {
  local site="$1"
  local base="${site#www.}"
  cat <<EOF
127.0.0.1 $site
127.0.0.1 www.$base
::1       $site
::1       www.$base
EOF
}

block_sites() {
  echo "Blocking sites..."
  for site in "${SITES[@]}"; do
    while read -r entry; do
      if ! grep -qxF "$entry" "$HOSTS_FILE"; then
        echo "$entry" | sudo tee -a "$HOSTS_FILE" >/dev/null
      fi
    done < <(generate_entries "$site")
  done
  
  if command -v systemd-resolve &>/dev/null; then
    sudo systemd-resolve --flush-caches >/dev/null 2>&1
  elif command -v nscd &>/dev/null; then
    sudo service nscd restart >/dev/null 2>&1
  elif command -v dscacheutil &>/dev/null; then
    sudo dscacheutil -flushcache >/dev/null 2>&1
    sudo killall -HUP mDNSResponder >/dev/null 2>&1
  fi
  echo "Sites are now blocked."
}

unblock_sites() {
  echo "Unblocking sites..."
  sudo cp "$HOSTS_FILE" "${HOSTS_FILE}.bak"
  for site in "${SITES[@]}"; do
    base="${site#www.}"
    sudo sed -i.bak "/127\.0\.0\.1\s\+\(www\.\)\?$base/d" "$HOSTS_FILE"
    sudo sed -i.bak "/::1\s\+\(www\.\)\?$base/d" "$HOSTS_FILE"
  done
  if [[ -f "${HOSTS_FILE}.bak" ]]; then
    sudo rm -f "${HOSTS_FILE}.bak"
  fi
  if command -v systemd-resolve &>/dev/null; then
    sudo systemd-resolve --flush-caches >/dev/null 2>&1
  elif command -v nscd &>/dev/null; then
    sudo service nscd restart >/dev/null 2>&1
  elif command -v dscacheutil &>/dev/null; then
    sudo dscacheutil -flushcache >/dev/null 2>&1
    sudo killall -HUP mDNSResponder >/dev/null 2>&1
  fi
  echo "Sites are now unblocked."
}

display_progress() {
  local duration=$1
  local elapsed=0
  local width=50
  local bar_char="="
  local empty_char=" "
  
  echo -ne "\033[?25l"
  
  while [ $elapsed -lt $duration ]; do
    local percent=$((elapsed * 100 / duration))
    local filled=$((width * percent / 100))
    local empty=$((width - filled))
    
    printf "\rProgress: [%${filled}s%${empty}s] %d%% - %d/%d sec" \
           "$(printf "%0.s$bar_char" $(seq 1 $filled))" \
           "$(printf "%0.s$empty_char" $(seq 1 $empty))" \
           $percent $elapsed $duration
    
    sleep 1
    ((elapsed++))
  done
  
  printf "\rProgress: [%${width}s] 100%% - Complete!%s\n" "$(printf "%0.s$bar_char" $(seq 1 $width))" ""
  
  echo -ne "\033[?25h"
}

cleanup() {
  echo -e "\nScript interrupted. Cleaning up..."
  echo -ne "\033[?25h"
  unblock_sites
  echo "Exiting."
  exit 0
}

trap cleanup SIGINT SIGTERM SIGHUP

timer_mode=false
minutes=0

if [ $# -eq 0 ]; then
  timer_mode=true
  echo "Timer mode activated. How many minutes do you want to block sites for?"
  read -p "Enter minutes: " minutes
  
  if ! [[ "$minutes" =~ ^[0-9]+$ ]] || [ "$minutes" -le 0 ]; then
    echo "Error: Please enter a positive number of minutes."
    exit 1
  fi
  
  now=$(date +%s)
  target=$((now + minutes * 60))
  
elif [[ "$1" =~ ^[0-9]+$ ]]; then
  timer_mode=true
  minutes=$1
  
  if [ "$minutes" -le 0 ]; then
    echo "Error: Please enter a positive number of minutes."
    exit 1
  fi
  
  now=$(date +%s)
  target=$((now + minutes * 60))
  
else
  if ! [[ "$1" =~ ^([01][0-9]|2[0-3]):([0-5][0-9])$ ]]; then
    echo "Usage: $0 [END_TIME(HH:MM)|MINUTES] [SITE_LIST]"
    echo "  If no arguments are given, script will ask for minutes interactively."
    exit 1
  fi
  END_HOUR=${BASH_REMATCH[1]}
  END_MIN=${BASH_REMATCH[2]}

  now=$(date +%s)
  target=$(date -d "today $END_HOUR:$END_MIN" +%s 2>/dev/null)

  if [ $? -ne 0 ]; then
    target=$(date -j -f "%H:%M" "$END_HOUR:$END_MIN" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo "Error: Could not parse time. Make sure you're using HH:MM format."
      exit 1
    fi
    current_date=$(date +%Y%m%d)
    target_date=$(date -j -f "%Y%m%d%H%M" "${current_date}${END_HOUR}${END_MIN}" +%s)
    target=$target_date
  fi

  if [ "$target" -le "$now" ]; then
    if command -v date | grep -q "gnu"; then
      target=$(date -d "tomorrow $END_HOUR:$END_MIN" +%s)
    else
      tomorrow=$(date -v+1d +%Y%m%d)
      target=$(date -j -f "%Y%m%d%H%M" "${tomorrow}${END_HOUR}${END_MIN}" +%s)
    fi
  fi
fi

block_sites

sleep_seconds=$(( target - now ))

if [ "$timer_mode" = true ]; then
  echo "Sites blocked for $minutes minutes."
  echo "Press Ctrl+C to cancel and unblock immediately"
  
  display_progress "$sleep_seconds"
else
  printf "Will unblock at %s (in %02d:%02d hours:minutes)\n" \
         "$(date -d @$target "+%H:%M" 2>/dev/null || date -r $target "+%H:%M")" \
         $((sleep_seconds/3600)) $(( (sleep_seconds%3600)/60 ))
  echo "Press Ctrl+C to cancel and unblock immediately"
  
  sleep "$sleep_seconds" || true
fi

unblock_sites