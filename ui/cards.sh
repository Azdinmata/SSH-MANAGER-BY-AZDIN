#!/bin/bash
export LC_ALL=C

draw_user_card() {
    local u="$1" p="$2" exp="$3" lim="$4" bw="$5"
    local dom=$(cat "/etc/ssh-manager/domain.conf" 2>/dev/null || echo "127.0.0.1")
    local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))" 2>/dev/null || echo "none")

    local vmess_json="{\"v\":\"2\",\"ps\":\"$u\",\"add\":\"$dom\",\"port\":\"443\",\"id\":\"$u_uuid\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$dom\",\"path\":\"/v2ray\",\"tls\":\"tls\",\"sni\":\"$dom\"}"
    local vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w 0 2>/dev/null || true)"
    local trojan_link="trojan://$p@$dom:443?security=tls&sni=$dom&type=ws&path=%2Ftrojan#$u"
    local vless_link="vless://$u_uuid@$dom:443?security=tls&encryption=none&type=ws&sni=$dom&path=%2Fvless#$u"

    echo ""
    echo -e "${C_YELLOW}┌────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET}           ${C_BOLD}${C_CYAN}ACCOUNT CREDENTIALS${C_RESET}          ${C_YELLOW}│${C_RESET}"
    echo -e "${C_YELLOW}├────────────────────────────────────────┤${C_RESET}"
    printf "${C_YELLOW}│${C_RESET} USER  : ${C_BOLD}%-30s${C_RESET} ${C_YELLOW}│${C_RESET}\n" "$u"
    printf "${C_YELLOW}│${C_RESET} PASS  : ${C_BOLD}%-30s${C_RESET} ${C_YELLOW}│${C_RESET}\n" "$p"
    printf "${C_YELLOW}│${C_RESET} EXP   : %-30s ${C_YELLOW}│${C_RESET}\n" "$exp"
    printf "${C_YELLOW}│${C_RESET} LIMIT : %-30s ${C_YELLOW}│${C_RESET}\n" "$lim Devices | $([ "$bw" = "0" ] && echo "Unlim" || echo "$bw GB")"
    echo -e "${C_YELLOW}├────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET} ${C_GREEN}VLESS Link:${C_RESET}                           ${C_YELLOW}│${C_RESET}"
    for chunk in $(echo "$vless_link" | fold -w 38); do
        printf "${C_YELLOW}│${C_RESET} ${C_GRAY}%-38s${C_RESET} ${C_YELLOW}│${C_RESET}\n" "$chunk"
    done
    echo -e "${C_YELLOW}├────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET} ${C_GREEN}Trojan Link:${C_RESET}                          ${C_YELLOW}│${C_YELLOW}"
    for chunk in $(echo "$trojan_link" | fold -w 38); do
        printf "${C_YELLOW}│${C_RESET} ${C_GRAY}%-38s${C_RESET} ${C_YELLOW}│${C_RESET}\n" "$chunk"
    done
    echo -e "${C_YELLOW}├────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET} ${C_GREEN}VMess Link:${C_RESET}                           ${C_YELLOW}│${C_RESET}"
    for chunk in $(echo "$vmess_link" | fold -w 38); do
        printf "${C_YELLOW}│${C_RESET} ${C_GRAY}%-38s${C_RESET} ${C_YELLOW}│${C_RESET}\n" "$chunk"
    done
    echo -e "${C_YELLOW}└────────────────────────────────────────┘${C_RESET}"
}
