#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

COMPOSE_FILE="docker-compose.yml"
DOCKER_USER="nessnetwork"
PROFILE="full"            # full | pi3 | mcp-server | mcp-client
DNS_MODE="hybrid"          # icann | hybrid | emerdns

DNS_LABEL_FILE="$SCRIPT_DIR/.dns_mode_labels"
DNS_LABEL_ICANN="ICANN-only (deny EmerDNS)"
DNS_LABEL_HYBRID="Hybrid (EmerDNS first, ICANN fallback)"
DNS_LABEL_EMERDNS="EmerDNS-only (deny ICANN)"

# Service bundles per profile (adjust as services become available)
PI3_SERVICES=(
  emercoin-core
  privateness
  skywire
  dns-reverse-proxy
  pyuheprng
  privatenesstools
  ipfs
)

MCP_SERVER_SERVICES=(
  emercoin-mcp-server
  privateness-mcp-server
  magic-wormhole-rendezvous
  magic-wormhole-transit
)

MCP_CLIENT_SERVICES=(
  emercoin-mcp-app
  privateness-mcp-app
  magic-wormhole-client
)

cyan="\033[1;36m"
magenta="\033[1;35m"
yellow="\033[1;33m"
green="\033[1;32m"
red="\033[1;31m"

# NESS dark theme palette (foreground-only so background stays deep charcoal)
primary="\033[38;5;45m"
accent="\033[38;5;208m"
muted="\033[38;5;244m"
panel_fg="\033[38;5;252m"
panel_border="\033[38;5;239m"
panel_bg="\033[48;5;233m"
title_glow="\033[38;5;213m"
reset="\033[0m"

check_ok_symbol="✔"
check_fail_symbol="✘"

load_dns_labels() {
  if [ -f "$DNS_LABEL_FILE" ]; then
    while IFS='=' read -r key value; do
      value=${value%$'\r'}
      case "$key" in
        icann) DNS_LABEL_ICANN="$value" ;;
        hybrid) DNS_LABEL_HYBRID="$value" ;;
        emerdns) DNS_LABEL_EMERDNS="$value" ;;
      esac
    done < "$DNS_LABEL_FILE"
  fi
}

save_dns_labels() {
  cat > "$DNS_LABEL_FILE" <<EOF
icann=$DNS_LABEL_ICANN
hybrid=$DNS_LABEL_HYBRID
emerdns=$DNS_LABEL_EMERDNS
EOF
}

apply_dns_mode() {
  case "$DNS_MODE" in
    icann)
      DNS_DESC="$DNS_LABEL_ICANN"
      DNS_SERVERS="1.1.1.1 8.8.8.8"
      ;;
    emerdns)
      DNS_DESC="$DNS_LABEL_EMERDNS"
      DNS_SERVERS="127.0.0.1"
      ;;
    *)
      DNS_MODE="hybrid"
      DNS_DESC="$DNS_LABEL_HYBRID"
      DNS_SERVERS="127.0.0.1 1.1.1.1"
      ;;
  esac
  export DNS_MODE DNS_DESC DNS_SERVERS
}

select_dns_mode() {
  echo
  echo -e "${green}Select Reality / DNS Mode:${reset}"
  echo "  0) ${DNS_LABEL_ICANN}"
  echo "  1) ${DNS_LABEL_HYBRID}"
  echo "  2) ${DNS_LABEL_EMERDNS}"
  echo
  read -rp "Select DNS mode [0-2]: " d_choice
  case "$d_choice" in
    0) DNS_MODE="icann" ;;
    1) DNS_MODE="hybrid" ;;
    2) DNS_MODE="emerdns" ;;
    *) echo "Invalid choice, keeping current: $DNS_MODE" ;;
  esac
  apply_dns_mode
  echo -e "${yellow}DNS mode set to: ${DNS_MODE} (${DNS_DESC})${reset}"
}

edit_dns_mode_labels() {
  echo
  echo -e "${green}Customize Reality / DNS Mode Names:${reset}"
  read -rp "Label for ICANN-only [${DNS_LABEL_ICANN}]: " input
  if [ -n "$input" ]; then DNS_LABEL_ICANN="$input"; fi
  read -rp "Label for Hybrid [${DNS_LABEL_HYBRID}]: " input
  if [ -n "$input" ]; then DNS_LABEL_HYBRID="$input"; fi
  read -rp "Label for EmerDNS-only [${DNS_LABEL_EMERDNS}]: " input
  if [ -n "$input" ]; then DNS_LABEL_EMERDNS="$input"; fi
  save_dns_labels
  apply_dns_mode
  echo -e "${yellow}Reality mode labels updated.${reset}"
}

profile_label() {
  case "$1" in
    pi3) echo "Pi 3 Essentials" ;;
    full) echo "Full Node" ;;
    mcp-server) echo "MCP Server Suite" ;;
    mcp-client) echo "MCP Client Suite" ;;
    *) echo "$1" ;;
  esac
}

select_profile() {
  echo
  echo -e "${green}Select Deployment Profile:${reset}"
  echo "  1) Pi 3 Essentials (Emercoin, Privateness, DNS, Skywire, Tools)"
  echo "  2) Full Node (everything in docker-compose.yml)"
  echo "  3) MCP Server Suite (MCP daemons, wormhole rendezvous)"
  echo "  4) MCP Client Suite (apps, QR helpers, wormhole client)"
  echo
  read -rp "Select profile [1-4]: " p_choice
  case "$p_choice" in
    1) PROFILE="pi3" ;;
    2) PROFILE="full" ;;
    3) PROFILE="mcp-server" ;;
    4) PROFILE="mcp-client" ;;
    *) echo "Invalid choice, keeping current: $(profile_label "$PROFILE")" ;;
  esac
  echo -e "${yellow}Profile set to: $(profile_label "$PROFILE")${reset}"
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${red}Docker is required but not installed.${reset}"
    return 1
  fi
  return 0
}

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

compose_up_services() {
  local services=("$@")
  if [ ${#services[@]} -eq 0 ]; then
    echo "No services defined for this profile yet."
    return 1
  fi
  compose up -d "${services[@]}"
}

wait_for_emercoin_core() {
  if ! docker ps --format '{{.Names}}' | grep -q '^emercoin-core$'; then
    return 0
  fi
  echo "Waiting for emercoin-core RPC to become healthy..."
  for _ in {1..30}; do
    status=$(docker inspect --format='{{.State.Health.Status}}' emercoin-core 2>/dev/null || echo "unknown")
    if [ "$status" = "healthy" ]; then
      echo "emercoin-core is healthy."
      return 0
    fi
    sleep 2
  done
  echo "emercoin-core health check timed out (continuing)."
}

start_stack() {
  echo
  echo -e "${yellow}Starting Ness stack (Profile: $(profile_label "$PROFILE"))...${reset}"
  require_docker || return 1

  case "$PROFILE" in
    pi3)
      compose_up_services "${PI3_SERVICES[@]}" || return 1
      wait_for_emercoin_core || true
      ;;
    full)
      compose up -d || return 1
      wait_for_emercoin_core || true
      ;;
    mcp-server)
      compose_up_services "${MCP_SERVER_SERVICES[@]}" || return 1
      ;;
    mcp-client)
      compose_up_services "${MCP_CLIENT_SERVICES[@]}" || return 1
      ;;
    *)
      echo "Unknown profile: $PROFILE"
      return 1
      ;;
  esac
}

stack_status() {
  require_docker || return 1
  compose ps
}

logs_stack() {
  require_docker || return 1
  compose logs -f
}

remove_everything_local() {
  require_docker || return 1
  echo -e "${yellow}Stopping all running Docker containers...${reset}"
  docker ps -aq | xargs -r docker stop
  echo -e "${yellow}Removing all Docker containers...${reset}"
  docker ps -aq | xargs -r docker rm -f
  echo -e "${yellow}Pruning Docker data (images, cache, volumes)...${reset}"
  docker system prune -af --volumes
  echo -e "${green}Docker cleanup complete.${reset}"
}

build_images_menu() {
  echo
  echo -e "${green}Build Images:${reset}"
  echo "  1) build-all.sh"
  echo "  2) build-multiarch.sh"
  echo "  0) Back"
  echo
  read -rp "Select option: " b_choice
  case "$b_choice" in
    1) ./build-all.sh ;;
    2) ./build-multiarch.sh ;;
    0) return 0 ;;
    *) echo "Invalid option." ;;
  esac
}

check_entropy() {
  echo -e "${yellow}Entropy check placeholder:${reset} ensure UHE 1536-bit generators are active (RC4OK + UHEPRNG)."
}

print_info() {
  echo -e "${panel_bg}${title_glow}"
  logo 2>/dev/null || true
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
  disk=$(df -h / 2>/dev/null || echo "?")

  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    docker_status="running"
  elif command -v docker >/dev/null 2>&1; then
    docker_status="installed (daemon not running)"
  else
    docker_status="not installed"
  fi

  stack=$(stack_status 2>/dev/null | wc -l)

  local box_top="${panel_bg}${panel_border}┌────────────────────────────────────────────┐${reset}"
  local box_mid="${panel_bg}${panel_border}├────────────────────────────────────────────┤${reset}"
  local box_bottom="${panel_bg}${panel_border}└────────────────────────────────────────────┘${reset}"

  echo -e "$box_top"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Host" "$panel_fg" "$host" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "OS" "$panel_fg" "$os" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Kernel" "$panel_fg" "$kernel" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Uptime" "$panel_fg" "$uptime" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "CPU" "$panel_fg" "${cpu:-"?"}" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Memory" "$panel_fg" "$mem" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Disk (/)" "$panel_fg" "$disk" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Docker" "$panel_fg" "$docker_status" "$reset"
  echo -e "$box_mid"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Reality" "$accent" "$DNS_MODE → $DNS_DESC" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Profile" "$primary" "$(profile_label "$PROFILE")" "$reset"
  printf "%b│ %b%-15s%b %s%b\n" "$panel_bg" "$muted" "Docker User" "$panel_fg" "$DOCKER_USER" "$reset"
  echo -e "$box_bottom"
}

logo() {
  local lines=(
" _   _                     _   _                   _   _            "
"| \\ | |                   | \\ | |                 | \\ | |           "
"|  \\| | ___  ___ ___ _ __ |  \\| | ___  _ __ ___   |  \\| | _____   __"
"| . ` |/ _ \\/ __/ _ \\ '_ \\| . ` |/ _ \\| '_ ` _ \\  | . ` |/ _ \\ \\ / /"
"| |\\  |  __/ (_|  __/ | | | |\\  | (_) | | | | | | | |\\  |  __/\\ V / "
"\\_| \\_/\\___|\\___\\___|_| |_|_| \\_/\\___/|_| |_| |_| \\_| \\_/\\___| \\_/  "
  )
  local palette=($primary $accent $title_glow $primary $accent $title_glow)
  local i=0
  for line in "${lines[@]}"; do
    local color="${palette[$((i % ${#palette[@]}))]}"
    echo -e "${panel_bg}${color}${line}${reset}"
    ((i++))
  done
}

menu() {
  while true; do
    clear
    print_info
    echo
    echo -e "${panel_bg}${panel_border}╔══════════════════╦═══════════════════════════════╗${reset}"
    printf "%b║ %bMenu V3%b          ║ %bReality:%b %s → %s%b\n" "$panel_bg" "$primary" "$panel_border" "$muted" "$accent" "$DNS_MODE" "$DNS_DESC" "$reset"
    echo -e "${panel_bg}${panel_border}╠══════════════════╩═══════════════════════════════╣${reset}"

    local menu_items=(
      "${accent}[0]${reset} Reality / DNS Mode"
      "${accent}[1]${reset} Select Profile"
      "${accent}[2]${reset} Build images"
      "${accent}[3]${reset} Start stack"
      "${accent}[4]${reset} Show stack status"
      "${accent}[5]${reset} Tail stack logs"
      "${accent}[6]${reset} Check entropy"
      "${accent}[7]${reset} Remove everything local"
      "${accent}[8]${reset} Rename Reality Modes"
      "${accent}[9]${reset} Exit"
    )
    for item in "${menu_items[@]}"; do
      echo -e "${panel_bg}${panel_fg}  ${item}${reset}"
    done
    echo -e "${panel_bg}${panel_border}╚═══════════════════════════════════════════════════╝${reset}"

    echo
    read -rp "Select an option: " choice
    case "$choice" in
      0) select_dns_mode ;;
      1) select_profile ;;
      2) build_images_menu ;;
      3) start_stack ;;
      4) stack_status ;;
      5) logs_stack ;;
      6) check_entropy ;;
      7) remove_everything_local ;;
      8) edit_dns_mode_labels ;;
      9) exit 0 ;;
      *) echo "Invalid choice." ;;
    esac
    echo
    read -rp "Press Enter to continue..." _pause
  done
}

load_dns_labels
apply_dns_mode
menu
