#!/bin/bash
export LC_ALL=C

draw_user_card() {
    local u="$1" p="$2" exp="$3" lim="$4" bw="$5"
    local dom=$(cat /etc/ssh-manager/domain.conf 2>/dev/null || echo "127.0.0.1")
    local ns_dom=$(cat /etc/ssh-manager/nsdomain.conf 2>/dev/null || echo "ns.domain.com")
    local pub_k=$([ -f /etc/ssh-manager/dnstt/server.pub ] && cat /etc/ssh-manager/dnstt/server.pub || echo "None")

    local u_uuid
    u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))" 2>/dev/null || echo "uuid-error")

    local vmess_json="{\"v\":\"2\",\"ps\":\"$u\",\"add\":\"$dom\",\"port\":\"443\",\"id\":\"$u_uuid\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$dom\",\"path\":\"/v2ray\",\"tls\":\"tls\",\"sni\":\"$dom\"}"
    local vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w 0 2>/dev/null || true)"
    local trojan_link="trojan://$p@$dom:443?security=tls&sni=$dom&type=ws&path=%2Ftrojan#$u"
    local vless_link="vless://$u_uuid@$dom:443?security=tls&encryption=none&type=ws&sni=$dom&path=%2Fvless#$u"

    echo ""
    echo -e "${C_YELLOW}┌──[ ACCOUNT CREDENTIALS ]───────────────┐${C_RESET}"
    printf "${C_YELLOW}│${C_RESET} USER  : ${C_BOLD}%-30s${C_RESET} ${C_YELLOW}│${C_RESET}\n" "$u"
    printf "${C_YELLOW}│${C_RESET} PASS  : ${C_BOLD}%-30s${C_RESET} ${C_YELLOW}│${C_RESET}\n" "$p"
    printf "${C_YELLOW}│${C_RESET} EXP   : %-30s ${C_YELLOW}│${C_RESET}\n" "$exp"
    printf "${C_YELLOW}│${C_RESET} LIMIT : %-30s ${C_YELLOW}│${C_RESET}\n" "$lim Devices | $([ "$bw" = "0" ] && echo "Unlim" || echo "$bw GB")"
    echo -e "${C_YELLOW}├──[ PROTOCOLS & PORTS ]─────────────────┤${C_RESET}"
    printf "${C_YELLOW}│${C_RESET} HOST/SNI : %-27s  ${C_YELLOW}│${C_RESET}\n" "$dom"
    echo -e "${C_YELLOW}│${C_RESET} SSH WS   : Port 443 | Path: /           ${C_YELLOW}│${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET} DIRECT   : Port 22                      ${C_YELLOW}│${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET} BADVPN   : Port 7300                    ${C_YELLOW}│${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET} UDP CUST : Ports 1-65535                ${C_YELLOW}│${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET} SLOWDNS  : NS: $ns_dom      ${C_YELLOW}│${C_RESET}"
    echo -e "${C_YELLOW}├──[ QUICK CONFIG LINKS ]────────────────┤${C_RESET}"
    echo -e "${C_YELLOW}│${C_RESET} ${C_GREEN}VLESS:${C_RESET}\n$vless_link\n"
    echo -e "${C_YELLOW}│${C_RESET} ${C_GREEN}TROJAN:${C_RESET}\n$trojan_link\n"
    echo -e "${C_YELLOW}│${C_RESET} ${C_GREEN}VMESS:${C_RESET}\n$vmess_link"
    echo -e "${C_YELLOW}└────────────────────────────────────────┘${C_RESET}"
}
