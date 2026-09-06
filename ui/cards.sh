#!/bin/bash
# ========================================================
# UI THEME: ACCOUNT & PROTOCOLS CREDENTIALS CARD
# ========================================================

draw_user_card() {
    local u="$1" p="$2" exp="$3" lim="$4" bw="$5"
    local s_domain=$(cat /etc/ssh-manager/domain.conf 2>/dev/null || echo "127.0.0.1")
    local ns_domain=$(cat /etc/ssh-manager/nsdomain.conf 2>/dev/null || echo "ns.domain.com")
    local pub_key=$([ -f "/etc/ssh-manager/dnstt/server.pub" ] && cat "/etc/ssh-manager/dnstt/server.pub" || echo "Not_Found")

    local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))")
    local vmess_json="{\"v\":\"2\",\"ps\":\"$u-VMess\",\"add\":\"$s_domain\",\"port\":\"443\",\"id\":\"$u_uuid\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$s_domain\",\"path\":\"/v2ray\",\"tls\":\"tls\",\"sni\":\"$s_domain\"}"
    local vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w 0)"
    local trojan_link="trojan://$p@$s_domain:443?security=tls&sni=$s_domain&type=ws&path=%2Ftrojan#$u-Trojan"
    local vless_link="vless://$u_uuid@$s_domain:443?security=tls&encryption=none&type=ws&sni=$s_domain&path=%2Fvless#$u-VLESS"

    echo ""
    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}                   ${C_BOLD}${C_YELLOW}ACCOUNT CREDENTIALS & PROTOCOL SUITE${C_RESET}                ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    printf "${C_CYAN}║${C_RESET}  ${C_PURPLE}Username${C_RESET}     : %-58s ${C_CYAN}║${C_RESET}\n" "$u"
    printf "${C_CYAN}║${C_RESET}  ${C_PURPLE}Password${C_RESET}     : %-58s ${C_CYAN}║${C_RESET}\n" "$p"
    printf "${C_CYAN}║${C_RESET}  ${C_PURPLE}Unique UUID${C_RESET}  : %-58s ${C_CYAN}║${C_RESET}\n" "$u_uuid"
    printf "${C_CYAN}║${C_RESET}  ${C_PURPLE}Expiration${C_RESET}   : %-58s ${C_CYAN}║${C_RESET}\n" "$exp"
    printf "${C_CYAN}║${C_RESET}  ${C_PURPLE}Max Devices${C_RESET}  : %-58s ${C_CYAN}║${C_RESET}\n" "$lim Concurrent"
    printf "${C_CYAN}║${C_RESET}  ${C_PURPLE}Bandwidth${C_RESET}    : %-58s ${C_CYAN}║${C_RESET}\n" "$([ "$bw" == "0" ] && echo "Unlimited" || echo "$bw GB")"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET} ${C_BOLD}[1] SSH WS / Direct / BadVPN / UDP Custom${C_RESET}                                    ${C_CYAN}║${C_RESET}"
    printf "${C_CYAN}║${C_RESET}     Host/SNI : %-60s ${C_CYAN}║${C_RESET}\n" "$s_domain"
    echo -e "${C_CYAN}║${C_RESET}     Ports    : Direct SSH (22), WS TLS (443), BadVPN UDP (7300)             ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}     UDP Cust : 1-65535 (DarkTunnel / UDP Custom App)                         ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}     Payload  : GET / HTTP/1.1[crlf]Host: $s_domain[crlf]Upgrade: websocket[crlf][crlf]  ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET} ${C_BOLD}[2] SlowDNS (DNSTT Tunnel)${C_RESET}                                                   ${C_CYAN}║${C_RESET}"
    printf "${C_CYAN}║${C_RESET}     NS Domain: %-60s ${C_CYAN}║${C_RESET}\n" "$ns_domain"
    printf "${C_CYAN}║${C_RESET}     Pub Key  : %-60s ${C_CYAN}║${C_RESET}\n" "$pub_key"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET} ${C_BOLD}[3] Trojan (WS + TLS)${C_RESET}                                                         ${C_CYAN}║${C_RESET}"
    printf "${C_CYAN}║${C_RESET}  ${C_GREEN}%-74s${C_RESET} ${C_CYAN}║${C_RESET}\n" "$trojan_link"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET} ${C_BOLD}[4] VMess (WS + TLS)${C_RESET}                                                          ${C_CYAN}║${C_RESET}"
    printf "${C_CYAN}║${C_RESET}  ${C_GREEN}%-74s${C_RESET} ${C_CYAN}║${C_RESET}\n" "$vmess_link"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET} ${C_BOLD}[5] VLESS (WS + TLS)${C_RESET}                                                          ${C_CYAN}║${C_RESET}"
    printf "${C_CYAN}║${C_RESET}  ${C_GREEN}%-74s${C_RESET} ${C_CYAN}║${C_RESET}\n" "$vless_link"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${C_RESET}"
}
