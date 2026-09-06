#!/bin/bash
# ========================================================
# UI THEME: ASCII BANNER & SYSTEM STATUS BAR
# ========================================================

draw_banner() {
    clear
    echo -e "${C_CYAN}  ███████╗███████╗██╗  ██╗   ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ ${C_RESET}"
    echo -e "${C_BLUE}  ██╔════╝██╔════╝██║  ██║   ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗${C_RESET}"
    echo -e "${C_PURPLE}  ███████╗███████╗███████║───██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝${C_RESET}"
    echo -e "${C_BLUE}  ╚════██║╚════██║██╔══██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗${C_RESET}"
    echo -e "${C_CYAN}  ███████║███████║██║  ██║   ██║ └──╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║${C_RESET}"
    echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "              ${C_BOLD}${C_YELLOW}[ SSH-MANAGER By-AZDIN  |  ALL-IN-ONE SUITE v5.0 ]${C_RESET}"
    echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────────────${C_RESET}"

    local os_info=$(grep -oP '(?<=PRETTY_NAME=")[^"]*' /etc/os-release 2>/dev/null || echo "Linux")
    local mem_usage=$(free -m | awk '/Mem:/ {printf "%.1f%%", $3*100/$2}')
    local total_accs=$(wc -l < /etc/ssh-manager/users.db 2>/dev/null || echo "0")
    local cur_domain=$(cat /etc/ssh-manager/domain.conf 2>/dev/null || echo "127.0.0.1")

    printf "${C_CYAN}  OS:${C_RESET} %-12s ${C_PURPLE}Domain:${C_RESET} %-20s ${C_BLUE}RAM:${C_RESET} %-6s ${C_GREEN}Accounts:${C_RESET} %-3s\n" "$os_info" "$cur_domain" "$mem_usage" "$total_accs"
    echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────────────${C_RESET}"
}
