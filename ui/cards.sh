#!/bin/bash
export LC_ALL=C

draw_user_card() {
    local u="$1" p="$2" exp="$3" lim="$4" bw="$5"
    local s_domain="127.0.0.1"
    local ns_domain="ns.domain.com"
    local pub_key="Not_Generated"

    [ -f /etc/ssh-manager/domain.conf ] && s_domain=$(cat /etc/ssh-manager/domain.conf)
    [ -f /etc/ssh-manager/nsdomain.conf ] && ns_domain=$(cat /etc/ssh-manager/nsdomain.conf)
    [ -f /etc/ssh-manager/dnstt/server.pub ] && pub_key=$(cat /etc/ssh-manager/dnstt/server.pub)

    local u_uuid
    u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))" 2>/dev/null || echo "00000000-0000-0000-0000-000000000000")
    
    local vmess_json="{\"v\":\"2\",\"ps\":\"$u-VMess\",\"add\":\"$s_domain\",\"port\":\"443\",\"id\":\"$u_uuid\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$s_domain\",\"path\":\"/v2ray\",\"tls\":\"tls\",\"sni\":\"$s_domain\"}"
    local vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w 0 2>/dev/null || echo "")"
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
    printf "${C_CYAN}║${C_RESET}     Ports    : %-60s ${C_CYAN}║${C_RESET}\n" "Direct SSH: 22 | WS TLS: 443 | BadVPN: 7300"
    printf "${C_CYAN}║${C_RESET}     UDP Cust : %-60s ${C_CYAN}║${C_RESET}\n" "Ports 1-65535"
    printf "${C_CYAN}║${C_RESET}     Payload  : %-60s ${C_CYAN}║${C_RESET}\n" "GET / HTTP/1.1[crlf]Host: $s_domain[crlf]Upgrade: ws"
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
