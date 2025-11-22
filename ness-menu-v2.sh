#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

COMPOSE_FILE="docker-compose.yml"
DOCKER_USER="nessnetwork"
PROFILE="full" # Default to full, user can change

cyan="\033[1;36m"
magenta="\033[1;35m"
yellow="\033[1;33m"
green="\033[1;32m"
red="\033[1;31m"
reset="\033[0m"

check_ok_symbol="✔"
check_fail_symbol="✘"

# ... logo ...

select_profile() {
  echo
  echo -e "${green}Select Hardware Profile:${reset}"
  echo "  1) Raspberry Pi 3 / Low Spec (Essentials Only)"
  echo "     -> Runs: Emercoin, Privateness, Skywire, DNS, Amnezia"
  echo "     -> Skips: Yggdrasil, I2P, Unified (Heavy/Unstable on Pi3)"
  echo
  echo "  2) Raspberry Pi 4 / PC (Full Node)"
  echo "     -> Runs: EVERYTHING"
  echo
  read -rp "Select profile [1-2]: " p_choice
  case "$p_choice" in
    1)
      PROFILE="pi3"
      echo -e "${yellow}Profile set to: Pi 3 (Essentials)${reset}"
      ;;
    2)
      PROFILE="full"
      echo -e "${yellow}Profile set to: Full Node${reset}"
      ;;
    *)
      echo "Invalid choice, keeping current: $PROFILE"
      ;;
  esac
}

start_stack() {
  echo
  echo -e "${yellow}Starting Ness stack (Profile: $PROFILE)...${reset}"
  
  require_docker || return 1

  if [ "$PROFILE" = "pi3" ]; then
    # Explicitly start ONLY the Pi 3 safe revenue stack
    compose up -d \
      emercoin-core \
      privateness \
      skywire \
      dns-reverse-proxy \
      pyuheprng \
      privatenesstools \
      privatenumer \
      amneziawg \
      skywire-amneziawg \
      amnezia-exit \
      ipfs
      # Note: Yggdrasil and I2P are excluded
  else
    # Start everything
    compose up -d
  fi

  wait_for_emercoin_core || true
}

print_info() {
  echo -e "${magenta}"
  logo
  echo -e "${reset}"

  # ... existing host checks ...
  local host os kernel uptime cpu mem disk docker_status stack
  host=$(hostname 2>/dev/null || echo "?")
  if [ -r /etc/os-release ]; then
    os=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
  else
    os=$(uname -s 2>/dev/null || echo "?")
  fi
  # ... keep existing logic ...
  kernel=$(uname -r 2>/dev/null || echo "?")
  uptime=$(uptime -p 2>/dev/null || echo "?")
  cpu=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^[ \t]*//' || echo "?")
  mem=$(free -h 2>/dev/null | awk '/Mem:/ {print $3 "/" $2}' || echo "?")
  disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}' || echo "?")

  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      docker_status="running"
    else
      docker_status="installed (daemon not running)"
    fi
  else
    docker_status="not installed"
  fi

  stack=$(stack_status 2>/dev/null || echo "unknown")

  echo -e "${cyan}Host${reset}:           $host"
  echo -e "${cyan}OS${reset}:             $os"
  echo -e "${cyan}Kernel${reset}:         $kernel"
  echo -e "${cyan}Uptime${reset}:         $uptime"
  echo -e "${cyan}CPU${reset}:            ${cpu:-"?"}"
  echo -e "${cyan}Memory${reset}:         $mem"
  echo -e "${cyan}Disk (/)${reset}:       $disk"
  echo -e "${cyan}Docker${reset}:         $docker_status"
  echo -e "${cyan}Ness stack${reset}:     $stack"
  echo -e "${cyan}Active Profile${reset}: ${yellow}$PROFILE${reset}"
  echo -e "${cyan}Docker User${reset}:    $DOCKER_USER"
}

# ... existing functions ...

menu() {
  while true; do
    clear
    print_info
    echo
    echo -e "${green}Menu V2 (Release Mode):${reset}"
    echo "  1) Select Hardware Profile (Current: $PROFILE)"
    echo "  2) Build images (Multi-Arch Release)"
    echo "  3) Start Ness Stack (Respects Profile)"
    echo "  4) Show stack status"
    echo "  5) Tail stack logs"
    echo "  6) Check entropy"
    echo "  7) Remove everything local"
    echo "  0) Exit"
    echo
    read -rp "Select an option: " choice
    case "$choice" in
      1) select_profile ;;
      2) build_images_menu ;;
      3) start_services_menu ;;
      4) status_stack ;;
      5) logs_stack ;;
      6) check_entropy ;;
      7) remove_everything_local ;;
      0) exit 0 ;;
      *) echo "Invalid choice." ;;
    esac
    echo
    read -rp "Press Enter to continue..." _pause
  done
}
