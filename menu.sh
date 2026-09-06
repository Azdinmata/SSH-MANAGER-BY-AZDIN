#!/bin/bash
export LC_ALL=C
clear

DB_FILE="/etc/ssh-manager/users.db"
CONF_DIR="/etc/ssh-manager"
DOMAIN_FILE="/etc/ssh-manager/domain.conf"
NS_FILE="/etc/ssh-manager/nsdomain.conf"
DNSTT_PUB="/etc/ssh-manager/dnstt/server.pub"

mkdir -p "$CONF_DIR"
touch "$DB_FILE"
[[ ! -f "$DOMAIN_FILE" ]] && echo "127.0.0.1" > "$DOMAIN_FILE"
[[ ! -f "$NS_FILE" ]] && echo "ns.yourdomain.com" > "$NS_FILE"
SERVER_DOMAIN=$(cat "$DOMAIN_FILE")
NS_DOMAIN=$(cat "$NS_FILE")
PUB_KEY=$([ -f "$DNSTT_PUB" ] && cat "$DNSTT_PUB" || echo "Not_Generated")

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_CYAN="\033[38;5;51m"
C_BLUE="\033[38;5;39m"
C_PURPLE="\033[38;5;141m"
C_GREEN="\033[38;5;48m"
C_YELLOW="\033[38;5;220m"
C_RED="\033[38;5;196m"
C_GRAY="\033[38;5;244m"

print_banner() {
    clear
    echo -e "${C_CYAN}  ███████╗███████╗██╗  ██╗   ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ ${C_RESET}"
    echo -e "${C_BLUE}  ██╔════╝██╔════╝██║  ██║   ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗${C_RESET}"
    echo -e "${C_PURPLE}  ███████╗███████╗███████║───██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝${C_RESET}"
    echo -e "${C_BLUE}  ╚════██║╚════██║██╔══██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗${C_RESET}"
    echo -e "${C_CYAN}  ███████║███████║██║  ██║   ██║ └──╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║${C_RESET}"
    echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "              ${C_BOLD}${C_YELLOW}[ SSH-MANAGER By-AZDIN  |  ALL-IN-ONE SUITE v5.0 ]${C_RESET}"
    echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────────────${C_RESET}"
    local os_info=$(grep -oP "(?<=PRETTY_NAME=\")[^\"]*" /etc/os-release 2>/dev/null || echo "Linux")
    local mem_usage=$(free -m | awk '/Mem:/ {printf "%.1f%%", $3*100/$2}')
    local total_accs=$(wc -l < "$DB_FILE" 2>/dev/null || echo "0")
    printf "${C_CYAN}  OS:${C_RESET} %-12s ${C_PURPLE}Domain:${C_RESET} %-20s ${C_BLUE}RAM:${C_RESET} %-6s ${C_GREEN}Accounts:${C_RESET} %-3s\n" "$os_info" "$SERVER_DOMAIN" "$mem_usage" "$total_accs"
    echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────────────${C_RESET}"
}

pause() {
    echo ""
    read -p "  Press [Enter] key to continue..." _
}

sync_v2ray() {
    local u="$1" p="$2" uuid="$3" action="$4"
    python3 -c '
import json, sys
path = "/usr/local/etc/v2ray/config.json"
try:
    with open(path, "r") as f: cfg = json.load(f)
except Exception: sys.exit(0)

u, pwd, uuid_str, act = sys.argv[1:5]
for ib in cfg.get("inbounds", []):
    port = ib.get("port")
    clients = ib.get("settings", {}).get("clients", [])
    if port == 10000:
        clients = [c for c in clients if c.get("id") != uuid_str and c.get("email") != u]
        if act in ["add", "update"]: clients.append({"id": uuid_str, "alterId": 0, "email": u})
    elif port == 10001:
        clients = [c for c in clients if c.get("password") != pwd and c.get("email") != u]
        if act in ["add", "update"]: clients.append({"password": pwd, "email": u})
    elif port == 10002:
        clients = [c for c in clients if c.get("id") != uuid_str and c.get("email") != u]
        if act in ["add", "update"]: clients.append({"id": uuid_str, "email": u})
    ib["settings"]["clients"] = clients

with open(path, "w") as f: json.dump(cfg, f, indent=2)
' "$u" "$p" "$uuid" "$action"
    systemctl restart v2ray 2>/dev/null || true
}

print_credentials_card() {
    local u="$1" p="$2" exp="$3" lim="$4" bw="$5"
    local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))")
    local vmess_json="{\"v\":\"2\",\"ps\":\"$u-VMess\",\"add\":\"$SERVER_DOMAIN\",\"port\":\"443\",\"id\":\"$u_uuid\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$SERVER_DOMAIN\",\"path\":\"/v2ray\",\"tls\":\"tls\",\"sni\":\"$SERVER_DOMAIN\"}"
    local vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w 0)"
    local trojan_link="trojan://$p@$SERVER_DOMAIN:443?security=tls&sni=$SERVER_DOMAIN&type=ws&path=%2Ftrojan#$u-Trojan"
    local vless_link="vless://$u_uuid@$SERVER_DOMAIN:443?security=tls&encryption=none&type=ws&sni=$SERVER_DOMAIN&path=%2Fvless#$u-VLESS"

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
    printf "${C_CYAN}║${C_RESET}     Host/SNI : %-60s ${C_CYAN}║${C_RESET}\n" "$SERVER_DOMAIN"
    printf "${C_CYAN}║${C_RESET}     Ports    : %-60s ${C_CYAN}║${C_RESET}\n" "SSH 22, WS TLS 443, BadVPN UDP 7300"
    printf "${C_CYAN}║${C_RESET}     UDP Cust : %-60s ${C_CYAN}║${C_RESET}\n" "Ports 1-65535"
    printf "${C_CYAN}║${C_RESET}     Payload  : %-60s ${C_CYAN}║${C_RESET}\n" "GET / HTTP/1.1[crlf]Host: $SERVER_DOMAIN[crlf]Upgrade: ws"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET} ${C_BOLD}[2] SlowDNS - DNSTT Mode${C_RESET}                                                     ${C_CYAN}║${C_RESET}"
    printf "${C_CYAN}║${C_RESET}     NS Domain: %-60s ${C_CYAN}║${C_RESET}\n" "$NS_DOMAIN"
    printf "${C_CYAN}║${C_RESET}     Pub Key  : %-60s ${C_CYAN}║${C_RESET}\n" "$PUB_KEY"
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

menu_users() {
    while true; do
        print_banner
        echo -e "${C_BOLD}${C_YELLOW}  [ CATEGORY: USER MANAGEMENT ]${C_RESET}\n"
        echo -e "  ${C_CYAN}[1]${C_RESET} Create Account (Custom or Lifetime)"
        echo -e "  ${C_CYAN}[2]${C_RESET} Edit Account (Pass, Expiry, Limit, Quota)"
        echo -e "  ${C_CYAN}[3]${C_RESET} List All Active Accounts"
        echo -e "  ${C_CYAN}[4]${C_RESET} View Credentials & Protocol Links"
        echo -e "  ${C_CYAN}[5]${C_RESET} Delete Account"
        echo -e "  ${C_CYAN}[0]${C_RESET} Back to Main Dashboard"
        echo ""
        read -p "  Action: " opt
        case "$opt" in
            1)
                echo ""
                read -p "  Enter Username: " u
                [[ -z "$u" ]] && continue
                if id "$u" &>/dev/null; then echo -e "  ${C_RED}User already exists!${C_RESET}"; pause; continue; fi
                read -p "  Enter Password: " p
                [[ -z "$p" ]] && continue
                read -p "  Duration in days (0 or never for Lifetime) [30]: " d
                d=${d:-30}
                if [[ "$d" == "0" || "${d,,}" == "never" ]]; then
                    exp="Never"
                else
                    exp=$(date -d "+$d days" +%Y-%m-%d)
                fi
                read -p "  Concurrency limit (Default: 2): " lim
                lim=${lim:-2}
                read -p "  Bandwidth limit GB (0 = unlimited) [0]: " bw
                bw=${bw:-0}

                if [[ "$exp" == "Never" ]]; then
                    useradd -M -s /bin/false "$u"
                    chage -E -1 "$u"
                else
                    useradd -M -s /bin/false -e "$exp" "$u"
                fi
                echo "$u:$p" | chpasswd
                usermod -U "$u" 2>/dev/null

                echo "$u:$p:$exp:$lim:$bw:" >> "$DB_FILE"
                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))")
                sync_v2ray "$u" "$p" "$u_uuid" "add"

                print_credentials_card "$u" "$p" "$exp" "$lim" "$bw"
                pause
                ;;
            2)
                echo ""
                read -p "  Enter Username to edit: " target
                local record=$(grep "^$target:" "$DB_FILE")
                if [[ -z "$record" ]]; then echo -e "  ${C_RED}User not found!${C_RESET}"; pause; continue; fi
                IFS=: read -r cur_u cur_p cur_exp cur_lim cur_bw _rest <<< "$record"
                
                read -p "  New Password [Enter to keep]: " np
                np=${np:-$cur_p}
                read -p "  New Concurrency Limit [Enter to keep]: " nlim
                nlim=${nlim:-$cur_lim}
                read -p "  New Bandwidth GB [Enter to keep]: " nbw
                nbw=${nbw:-$cur_bw}
                read -p "  New Duration in days (0 or never for Lifetime): " nd
                
                nexp="$cur_exp"
                if [[ "$nd" == "0" || "${nd,,}" == "never" ]]; then
                    nexp="Never"
                    chage -E -1 "$target"
                elif [[ -n "$nd" && "$nd" =~ ^[0-9]+$ ]]; then
                    nexp=$(date -d "+$nd days" +%Y-%m-%d)
                    usermod -e "$nexp" "$target"
                fi

                echo "$target:$np" | chpasswd
                sed -i "/^$target:/d" "$DB_FILE"
                echo "$target:$np:$nexp:$nlim:$nbw:" >> "$DB_FILE"

                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$target')))")
                sync_v2ray "$target" "$np" "$u_uuid" "update"

                print_credentials_card "$target" "$np" "$nexp" "$nlim" "$nbw"
                pause
                ;;
            3)
                echo ""
                printf "  ${C_CYAN}%-16s | %-16s | %-12s | %-8s | %-10s${C_RESET}\n" "USERNAME" "PASSWORD" "EXPIRY" "LIMIT" "QUOTA"
                echo -e "  ${C_GRAY}────────────────────────────────────────────────────────────────────────${C_RESET}"
                while IFS=: read -r u p exp lim bw _rest; do
                    [[ -z "$u" || "$u" =~ ^# ]] && continue
                    printf "  %-16s | %-16s | %-12s | %-8s | %-10s\n" "$u" "$p" "$exp" "$lim" "$([ "$bw" == "0" ] && echo "Unlimited" || echo "$bw GB")"
                done < "$DB_FILE"
                pause
                ;;
            4)
                echo ""
                read -p "  Enter Username: " target
                local record=$(grep "^$target:" "$DB_FILE")
                if [[ -z "$record" ]]; then echo -e "  ${C_RED}User not found!${C_RESET}"; pause; continue; fi
                IFS=: read -r u p exp lim bw _rest <<< "$record"
                print_credentials_card "$u" "$p" "$exp" "$lim" "$bw"
                pause
                ;;
            5)
                echo ""
                read -p "  Enter Username to delete: " target
                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$target')))")
                userdel -f "$target" 2>/dev/null
                sed -i "/^$target:/d" "$DB_FILE"
                sync_v2ray "$target" "" "$u_uuid" "delete"
                echo -e "  ${C_GREEN}User deleted.${C_RESET}"
                pause
                ;;
            0) break ;;
        esac
    done
}

menu_protocols() {
    while true; do
        print_banner
        echo -e "${C_BOLD}${C_YELLOW}  [ CATEGORY: PROTOCOLS & NETWORK SERVICES ]${C_RESET}\n"
        echo -e "  ${C_CYAN}[1]${C_RESET} Status of All Core Services"
        echo -e "  ${C_CYAN}[2]${C_RESET} Restart All Core Services"
        echo -e "  ${C_CYAN}[3]${C_RESET} BadVPN Gateway Port 7300 State"
        echo -e "  ${C_CYAN}[4]${C_RESET} UDP Custom Service State"
        echo -e "  ${C_CYAN}[5]${C_RESET} DNSTT SlowDNS State & Public Key"
        echo -e "  ${C_CYAN}[0]${C_RESET} Back to Main Dashboard"
        echo ""
        read -p "  Action: " opt
        case "$opt" in
            1)
                echo ""
                printf "  %-25s : " "SSH Daemon (Port 22)"
                systemctl is-active --quiet ssh && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "WS Bridge (Port 10015)"
                systemctl is-active --quiet ws-dropbear && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "V2Ray Engine (WS)"
                systemctl is-active --quiet v2ray && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "Nginx Edge Proxy (443)"
                systemctl is-active --quiet nginx && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "BadVPN 7300 Gateway"
                systemctl is-active --quiet badvpn && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "UDP Custom Service"
                systemctl is-active --quiet udp-custom && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "DNSTT SlowDNS (Port 53)"
                systemctl is-active --quiet dnstt && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                pause
                ;;
            2)
                systemctl restart ssh ws-dropbear v2ray nginx badvpn udp-custom dnstt 2>/dev/null || true
                echo -e "  ${C_GREEN}All core services restarted.${C_RESET}"
                pause
                ;;
            3)
                systemctl status badvpn --no-pager | head -n 10
                pause
                ;;
            4)
                systemctl status udp-custom --no-pager | head -n 10
                pause
                ;;
            5)
                echo -e "  ${C_CYAN}DNSTT Public Key:${C_RESET} $PUB_KEY"
                systemctl status dnstt --no-pager | head -n 10
                pause
                ;;
            0) break ;;
        esac
    done
}

uninstall_all() {
    echo ""
    echo -e "${C_RED}========================================================"
    echo -e "   WARNING: THIS WILL COMPLETELY PURGE SSH-MANAGER!     "
    echo -e "========================================================${C_RESET}"
    read -p "Are you absolutely sure you want to uninstall? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo -e "${C_YELLOW}Uninstall canceled.${C_RESET}"
        pause
        return
    fi

    echo -e "\n${C_RED}[*] Stopping all services...${C_RESET}"
    systemctl stop nginx v2ray badvpn udp-custom dnstt ws-dropbear 2>/dev/null || true
    systemctl disable nginx v2ray badvpn udp-custom dnstt ws-dropbear 2>/dev/null || true

    pkill -9 -f badvpn 2>/dev/null || true
    pkill -9 -f udp-custom 2>/dev/null || true
    pkill -9 -f dnstt-server 2>/dev/null || true
    pkill -9 -f v2ray 2>/dev/null || true
    pkill -9 -f ws-dropbear 2>/dev/null || true

    crontab -r 2>/dev/null || true

    if [ -f "$DB_FILE" ]; then
        while IFS=: read -r u _rest; do
            [[ -n "$u" && ! "$u" =~ ^# ]] && userdel -f "$u" 2>/dev/null || true
        done < "$DB_FILE"
    fi

    apt-get purge -y nginx v2ray certbot python3-certbot-nginx 2>/dev/null || true
    apt-get autoremove -y --purge 2>/dev/null || true

    rm -rf /etc/ssh-manager /usr/local/etc/v2ray /etc/v2ray /root/udp /etc/nginx/sites-available/* /etc/nginx/sites-enabled/* /etc/letsencrypt
    rm -f /usr/local/bin/ssh-manager /usr/local/bin/menu* /bin/menu /usr/local/bin/badvpn-udpgw /usr/local/bin/udp-custom /usr/local/bin/dnstt-server /usr/local/bin/ws-dropbear /usr/local/bin/session-watchdog
    rm -f /etc/systemd/system/badvpn.service /etc/systemd/system/udp-custom.service /etc/systemd/system/dnstt.service /etc/systemd/system/ws-dropbear.service
    systemctl daemon-reload

    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
    echo -e "${C_GREEN}✔ SSH-MANAGER has been completely uninstalled.${C_RESET}"
    exit 0
}

menu_settings() {
    while true; do
        print_banner
        echo -e "${C_BOLD}${C_YELLOW}  [ CATEGORY: SYSTEM, DOMAIN & SECURITY ]${C_RESET}\n"
        echo -e "  ${C_CYAN}[1]${C_RESET} Update Domain"
        echo -e "  ${C_CYAN}[2]${C_RESET} Update Nameserver - DNSTT NS"
        echo -e "  ${C_CYAN}[3]${C_RESET} Renew SSL Certificate"
        echo -e "  ${C_RED}[4]${C_RESET} Purge and Uninstall Everything"
        echo -e "  ${C_CYAN}[0]${C_RESET} Back to Main Dashboard"
        echo ""
        read -p "  Action: " opt
        case "$opt" in
            1)
                read -p "  Enter new domain: " ndom
                [[ -n "$ndom" ]] && echo "$ndom" > "$DOMAIN_FILE" && SERVER_DOMAIN="$ndom"
                pause
                ;;
            2)
                read -p "  Enter new NS domain: " nns
                [[ -n "$nns" ]] && echo "$nns" > "$NS_FILE" && NS_DOMAIN="$nns"
                systemctl restart dnstt 2>/dev/null || true
                pause
                ;;
            3)
                systemctl stop nginx
                certbot renew --quiet
                systemctl start nginx
                echo -e "  ${C_GREEN}SSL Renewed.${C_RESET}"
                pause
                ;;
            4) uninstall_all ;;
            0) break ;;
        esac
    done
}

while true; do
    print_banner
    echo -e "${C_BOLD}${C_YELLOW}  [ MAIN CONTROL HUB ]${C_RESET}\n"
    echo -e "  ${C_CYAN}[1]${C_RESET} User Management         ${C_GRAY}(Add, Lifetime, Limit, Quota)${C_RESET}"
    echo -e "  ${C_CYAN}[2]${C_RESET} Protocol Suite          ${C_GRAY}(SSH, Trojan, VMess, UDP, DNSTT)${C_RESET}"
    echo -e "  ${C_CYAN}[3]${C_RESET} System and Security     ${C_GRAY}(Domain, SSL, Uninstall)${C_RESET}"
    echo -e "  ${C_CYAN}[4]${C_RESET} Active Live Sessions    ${C_GRAY}(Connected Clients)${C_RESET}"
    echo -e "  ${C_CYAN}[0]${C_RESET} Exit"
    echo ""
    read -p "  Select [0-4]: " mc
    case "$mc" in
        1) menu_users ;;
        2) menu_protocols ;;
        3) menu_settings ;;
        4)
            print_banner
            who
            echo ""
            ss -tp '( sport = :22 or sport = :443 )' | head -n 15
            pause
            ;;
        0) clear; exit 0 ;;
    esac
done
