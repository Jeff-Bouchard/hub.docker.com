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

check_ok_symbol="✔"
check_fail_symbol="✘"

logo() {
  cat <<'EOF'

  ___       _                        ______     _ _        _____ _____ _____   _____ _             _    
 / _ \     | |                       |  ___|   | | |      |  _  /  ___|_   _| /  ___| |           | |   
/ /_\ \ ___| |_ __ _ _ __ _   _ ___  | |_ _   _| | |______| | | \ `--.  | |   \ `--.| |_ __ _  ___| | __
|  _  |/ __| __/ _` | '__| | | / __| |  _| | | | | |______| | | |`--. \ | |    `--. \ __/ _` |/ __| |/ /
| | | | (__| || (_| | |  | |_| \__ \ | | | |_| | | |      \ \_/ /\__/ /_| |_  /\__/ / || (_| | (__|   < 
\_| |_/\___|\__\__,_|_|   \__,_|___/ \_|  \__,_|_|_|       \___/\____/ \___/  \____/ \__\__,_|\___|_|\_\
                                                                                                        
                                                                                                        
______     _            _                             _   _      _                      _               
| ___ \   (_)          | |                           | \ | |    | |                    | |              
| |_/ / __ ___   ____ _| |_ ___ _ __   ___  ___ ___  |  \| | ___| |___      _____  _ __| | __           
|  __/ '__| \ \ / / _` | __/ _ \ '_ \ / _ \/ __/ __| | . ` |/ _ \ __\ \ /\ / / _ \| '__| |/ /           
| |  | |  | |\ V / (_| | ||  __/ | | |  __/\__ \__ \_| |\  |  __/ |_ \ V  V / (_) | |  |   <            
\_|  |_|  |_| \_/ \__,_|\__\___|_| |_|\___||___/___(_)_| \_/\___|\__| \_/\_/ \___/|_|  |_|\_\           
                                                                                                        
                                                                                                        
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

ping_host() {
  local host="$1"
  # Try Linux-style ping first; if it fails, fall back to Windows syntax.
  if ping -c 1 127.0.0.1 >/dev/null 2>&1; then
    ping -c 2 "$host"
  else
    ping -n 2 "$host"
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

remove_everything_local() {
  echo
  echo -e "${red}WARNING: This will remove all local Ness Docker containers, volumes, and images.${reset}"
  echo -e "${red}It does NOT touch any remote repositories (Docker Hub).${reset}"
  echo
  read -rp "Type 'ness' to confirm local cleanup: " answer
  if [ "$answer" != "ness" ]; then
    echo "Aborted."
    return 1
  fi

  require_docker || return 1

  echo
  echo -e "${yellow}Stopping and removing Ness Essential stack containers and volumes...${reset}"
  compose down -v || true

  echo
  echo -e "${yellow}Removing local Docker images in 'nessnetwork/*' or 'ness-network/*' namespaces...${reset}"
  local images
  images=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^ness(network|-)/' || true)
  if [ -n "$images" ]; then
    echo "$images" | xargs -r docker rmi -f
  else
    echo "No local Ness images found."
  fi

  echo
  echo -e "${green}Local cleanup complete.${reset}"
}

health_check() {
  echo
  echo -e "${yellow}Core node health check...${reset}"
  require_docker || return 1

   local overall_rc=0

  echo
  echo "== Docker services (Ness Essential stack) =="
  compose ps
  local rc_ps=$?
  if [ "$rc_ps" -eq 0 ]; then
    echo -e " ${green}${check_ok_symbol}${reset} Docker stack reachable"
  else
    echo -e " ${red}${check_fail_symbol}${reset} Docker stack reachable"
    overall_rc=1
  fi

  echo
  echo "== Privateness vs explorer (seq/block_hash) =="
  if docker ps --format '{{.Names}}' | grep -q '^privateness$'; then
    echo "-- Explorer:"
    local explorer_health
    explorer_health=$(curl -s https://ness-explorer.magnetosphere.net/api/health)
    local rc_explorer=$?
    echo "$explorer_health" | grep -E 'seq|block_hash' || true

    echo
    echo "-- Local node (privateness-cli status):"
    local local_status
    local_status=$(docker exec privateness privateness-cli status 2>/dev/null)
    local rc_local=$?
    echo "$local_status" | grep -E 'seq|block_hash' || true

    if [ "$rc_explorer" -eq 0 ] && echo "$explorer_health" | grep -q 'seq' \
       && [ "$rc_local" -eq 0 ] && echo "$local_status" | grep -q 'seq'; then
      echo -e " ${green}${check_ok_symbol}${reset} Privateness height/hash match explorer (seq/block_hash)"
    else
      echo -e " ${red}${check_fail_symbol}${reset} Privateness height/hash match explorer (seq/block_hash)"
      overall_rc=1
    fi
  else
    echo "privateness container is not running."
    echo -e " ${red}${check_fail_symbol}${reset} Privateness container running"
    overall_rc=1
  fi

  echo
  echo "== Emercoin vs explorer =="
  local EMERCOIN_CLI=""
  if command -v emercoin-cli >/dev/null 2>&1; then
    EMERCOIN_CLI="emercoin-cli"
  elif command -v emc >/dev/null 2>&1; then
    EMERCOIN_CLI="emc"
  fi

  if [ -n "$EMERCOIN_CLI" ]; then
    echo "-- Explorer block height:"
    local emc_height
    emc_height=$(curl -s https://explorer.emercoin.com/api/stats/block_height)
    local rc_emc_height=$?
    echo "$emc_height" || true

    echo
    echo "-- Local $EMERCOIN_CLI blocks:"
    local emc_local_info
    emc_local_info=$("$EMERCOIN_CLI" getblockchaininfo 2>/dev/null)
    local rc_emc_local=$?
    echo "$emc_local_info" | grep blocks || true

    echo
    echo "-- Explorer latest block hash:"
    local emc_explorer_hash
    emc_explorer_hash=$(curl -s https://explorer.emercoin.com/api/block/latest | grep blockhash)
    local rc_emc_explorer_hash=$?
    echo "$emc_explorer_hash" || true

    echo
    echo "-- Local $EMERCOIN_CLI best block hash:"
    local emc_local_hash
    emc_local_hash=$("$EMERCOIN_CLI" getbestblockhash 2>/dev/null)
    local rc_emc_local_hash=$?
    echo "$emc_local_hash" || true

    if [ "$rc_emc_height" -eq 0 ] && [ "$rc_emc_local" -eq 0 ] \
       && [ "$rc_emc_explorer_hash" -eq 0 ] && [ "$rc_emc_local_hash" -eq 0 ]; then
      echo -e " ${green}${check_ok_symbol}${reset} Emercoin height/hash match explorer (manual comparison)"
    else
      echo -e " ${red}${check_fail_symbol}${reset} Emercoin height/hash match explorer (manual comparison)"
      overall_rc=1
    fi
  else
    echo "emercoin-cli/emc not found on host; skipping Emercoin checks."
    echo -e " ${red}${check_fail_symbol}${reset} Emercoin CLI available on host"
    overall_rc=1
  fi

  echo
  echo "== EmerNVS & DNS resolution (host) =="
  if [ -n "$EMERCOIN_CLI" ]; then
    echo "-- NVS dns:private.ness:"
    if "$EMERCOIN_CLI" name_show dns:private.ness 2>/dev/null; then
      echo -e " ${green}${check_ok_symbol}${reset} NVS dns:private.ness reachable"
    else
      echo -e " ${red}${check_fail_symbol}${reset} NVS dns:private.ness reachable"
      overall_rc=1
    fi

    echo
    echo "-- Ping private.ness:"
    if ping_host private.ness; then
      echo -e " ${green}${check_ok_symbol}${reset} DNS resolution for private.ness"
    else
      echo -e " ${red}${check_fail_symbol}${reset} DNS resolution for private.ness"
      overall_rc=1
    fi

    echo
    echo "-- NVS dns:vpn.sky:"
    if "$EMERCOIN_CLI" name_show dns:vpn.sky 2>/dev/null; then
      echo -e " ${green}${check_ok_symbol}${reset} NVS dns:vpn.sky reachable"
    else
      echo -e " ${red}${check_fail_symbol}${reset} NVS dns:vpn.sky reachable"
      overall_rc=1
    fi

    echo
    echo "-- Ping vpn.sky:"
    if ping_host vpn.sky; then
      echo -e " ${green}${check_ok_symbol}${reset} DNS resolution for vpn.sky"
    else
      echo -e " ${red}${check_fail_symbol}${reset} DNS resolution for vpn.sky"
      overall_rc=1
    fi
  else
    echo "Emercoin CLI not found; skipping NVS checks."
  fi

  echo
  echo "-- Ping emercoin.com:"
  if ping_host emercoin.com; then
    echo -e " ${green}${check_ok_symbol}${reset} Internet connectivity to emercoin.com"
  else
    echo -e " ${red}${check_fail_symbol}${reset} Internet connectivity to emercoin.com"
    overall_rc=1
  fi

  echo
  if [ "$overall_rc" -eq 0 ]; then
    echo -e "${green}Global status: ${check_ok_symbol} All core node checks passed${reset}"
  else
    echo -e "${red}Global status: ${check_fail_symbol} Some core node checks failed${reset}"
  fi
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
    echo "  6) Core node health check"
    echo "  7) Remove everything local (containers/images/volumes)"
    echo "  0) Exit"
    echo
    read -rp "Select an option: " choice
    case "$choice" in
      1) start_stack ;;
      2) stop_stack ;;
      3) status_stack ;;
      4) logs_stack ;;
      5) check_entropy ;;
      6) health_check ;;
      7) remove_everything_local ;;
      0) exit 0 ;;
      *) echo "Invalid choice." ;;
    esac
    echo
    read -rp "Press Enter to continue..." _pause
  done
}

menu
