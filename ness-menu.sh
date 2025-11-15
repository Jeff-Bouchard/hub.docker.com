#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

COMPOSE_FILE="docker-compose.ness.yml"

cyan="\033[1;36m"
magenta="\033[1;35m"
yellow="\033[1;33m"
green="\033[1;32m"
red="\033[1;31m"
reset="\033[0m"

logo() {
  cat <<'EOF'
      _   _                      
 _ __| \ | | ___ _ __  ___  ___ 
| '__|  \| |/ _ \ '_ \/ __|/ _ \
| |  | |\  |  __/ | | \__ \  __/
|_|  |_| \_|\___|_| |_|___/\___|

 Privateness / Ness Network
EOF
}

compose() {
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f "$COMPOSE_FILE" "$@"
  else
    docker compose -f "$COMPOSE_FILE" "$@"
  fi
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${red}Docker is not installed or not in PATH.${reset}"
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo -e "${red}Docker daemon is not running.${reset}"
    return 1
  fi
}

stack_status() {
  if [ ! -f "$COMPOSE_FILE" ]; then
    echo "compose file $COMPOSE_FILE not found"
    return 1
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker not available"
    return 1
  fi

  local count
  count=$(compose ps 2>/dev/null | awk 'NR>2 && $1!="" {print $1}' | wc -l | tr -d ' ')
  if [ "$count" -eq 0 ] 2>/dev/null; then
    echo "stopped"
  else
    echo "$count service(s) listed"
  fi
}

print_info() {
  echo -e "${magenta}"
  logo
  echo -e "${reset}"

  local host os kernel uptime cpu mem disk docker_status stack
  host=$(hostname 2>/dev/null || echo "?")
  if [ -r /etc/os-release ]; then
    os=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
  else
    os=$(uname -s 2>/dev/null || echo "?")
  fi
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
}

check_entropy() {
  if [ -r /proc/sys/kernel/random/entropy_avail ]; then
    local val
    val=$(cat /proc/sys/kernel/random/entropy_avail)
    echo "Entropy available: $val"
  else
    echo "Entropy info not available on this system."
  fi
}

start_stack() {
  echo
  echo -e "${yellow}Starting Ness Essential stack...${reset}"
  if [ -x "./deploy-ness.sh" ]; then
    ./deploy-ness.sh
  else
    require_docker || return 1
    compose up -d
  fi
}

stop_stack() {
  echo
  echo -e "${yellow}Stopping Ness Essential stack...${reset}"
  require_docker || return 1
  compose down
}

status_stack() {
  echo
  echo -e "${yellow}Stack status:${reset}"
  require_docker || return 1
  compose ps
}

logs_stack() {
  echo
  echo -e "${yellow}Tailing stack logs (Ctrl+C to exit)...${reset}"
  require_docker || return 1
  compose logs -f
}

menu() {
  while true; do
    clear
    print_info
    echo
    echo -e "${green}Menu:${reset}"
    echo "  1) Start Ness Essential stack"
    echo "  2) Stop Ness Essential stack"
    echo "  3) Show stack status"
    echo "  4) Tail stack logs"
    echo "  5) Check entropy"
    echo "  0) Exit"
    echo
    read -rp "Select an option: " choice
    case "$choice" in
      1) start_stack ;;
      2) stop_stack ;;
      3) status_stack ;;
      4) logs_stack ;;
      5) check_entropy ;;
      0) exit 0 ;;
      *) echo "Invalid choice." ;;
    esac
    echo
    read -rp "Press Enter to continue..." _pause
  done
}

menu
