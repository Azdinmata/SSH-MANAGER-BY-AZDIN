#!/bin/bash
export LC_ALL=C

draw_banner() {
    # مسح الشاشة وسجل التمرير للأعلى بالكامل (Full Terminal & Scrollback Reset)
    printf "\033[2J\033[3J\033[H"
    
    local cur_domain="127.0.0.1"
    [ -f /etc/ssh-manager/domain.conf ] && cur_domain=$(cat /etc/ssh-manager/domain.conf)
    
    local cpu_load=$(top -bn1 2>/dev/null | awk -F',' '/Cpu\(s\)/ {print $1}' | awk '{print $2}' || echo "0.0")
    local mem_used=$(free -m | awk '/Mem:/ {print $3}')
    local mem_total=$(free -m | awk '/Mem:/ {print $2}')
    local mem_pct=$(( mem_used * 100 / (mem_total > 0 ? mem_total : 1) ))
    local s_up=$(uptime -p 2>/dev/null | sed -e 's/up //' -e 's/ hours\?/h/' -e 's/ minutes\?/m/' || echo "N/A")
    local online_ssh=$(who 2>/dev/null | wc -l)
    local total_accs=$(wc -l < /etc/ssh-manager/users.db 2>/dev/null || echo "0")

    local s_ssh="●"; systemctl is-active --quiet ssh && s_ssh="${C_GREEN}●${C_RESET}" || s_ssh="${C_RED}●${C_RESET}"
    local s_ws="●"; systemctl is-active --quiet ws-dropbear && s_ws="${C_GREEN}●${C_RESET}" || s_ws="${C_RED}●${C_RESET}"
    local s_v2r="●"; systemctl is-active --quiet v2ray && s_v2r="${C_GREEN}●${C_RESET}" || s_v2r="${C_RED}●${C_RESET}"
    local s_ngx="●"; systemctl is-active --quiet nginx && s_ngx="${C_GREEN}●${C_RESET}" || s_ngx="${C_RED}●${C_RESET}"
    local s_udp="●"; systemctl is-active --quiet udp-custom && s_udp="${C_GREEN}●${C_RESET}" || s_udp="${C_RED}●${C_RESET}"
    local s_dns="●"; systemctl is-active --quiet dnstt && s_dns="${C_GREEN}●${C_RESET}" || s_dns="${C_RED}●${C_RESET}"

    echo -e "${C_CYAN}┌────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}       ${C_BOLD}${C_YELLOW}SSH-MANAGER BY-AZDIN${C_RESET}             ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}├────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET} ${C_BOLD}TASK MANAGER (LIVE)${C_RESET}                    ${C_CYAN}│${C_RESET}"
    printf "${C_CYAN}│${C_RESET} CPU: ${C_YELLOW}%-5s${C_RESET} | RAM: ${C_YELLOW}%s/%sMB (%s%%)${C_RESET}  ${C_CYAN}│${C_RESET}\n" "${cpu_load}%" "$mem_used" "$mem_total" "$mem_pct"
    printf "${C_CYAN}│${C_RESET} UP : ${C_GREEN}%-6s${C_RESET} | ONLINE: ${C_GREEN}%-2s${C_RESET} | USERS: ${C_GREEN}%-3s${C_RESET} ${C_CYAN}│${C_RESET}\n" "$s_up" "$online_ssh" "$total_accs"
    echo -e "${C_CYAN}├────────────────────────────────────────┤${C_RESET}"
    printf "${C_CYAN}│${C_RESET} SRV: SSH:%b WS:%b V2R:%b NGX:%b UDP:%b DNS:%b ${C_CYAN}│${C_RESET}\n" "$s_ssh" "$s_ws" "$s_v2r" "$s_ngx" "$s_udp" "$s_dns"
    printf "${C_CYAN}│${C_RESET} DOM: ${C_PURPLE}%-33s${C_RESET} ${C_CYAN}│${C_RESET}\n" "$cur_domain"
    echo -e "${C_CYAN}└────────────────────────────────────────┘${C_RESET}"
}
