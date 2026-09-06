#!/bin/bash
export LC_ALL=C
clear

UI_DIR="/etc/ssh-manager/ui"
BASE_UI_URL="https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main/ui"

for comp in colors banner buttons cards; do
    if [ ! -f "$UI_DIR/$comp.sh" ]; then
        mkdir -p "$UI_DIR"
        curl -fsSL -o "$UI_DIR/$comp.sh" "$BASE_UI_URL/$comp.sh" 2>/dev/null
        chmod +x "$UI_DIR/$comp.sh" 2>/dev/null
    fi
    [ -f "$UI_DIR/$comp.sh" ] && source "$UI_DIR/$comp.sh"
done

DB_FILE="/etc/ssh-manager/users.db"
DOMAIN_FILE="/etc/ssh-manager/domain.conf"
NS_FILE="/etc/ssh-manager/nsdomain.conf"
touch "$DB_FILE"

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

menu_users() {
    while true; do
        draw_banner
        draw_category_header "USER MANAGEMENT"
        render_btn "1" "Create Unified Account" "(Custom / Lifetime / Limit / Quota)"
        render_btn "2" "Edit Existing Account"  "(Password, Expiry, Devices)"
        render_btn "3" "List All Users"         "(Status, Limits, Details)"
        render_btn "4" "Get Account Credentials" "(Extract Links & Configs)"
        render_btn "5" "Delete Account"         "(Purge from all protocols)"
        render_back_btn "Back to Main Dashboard"
        
        echo ""
        read -p "  Select action: " opt
        case "$opt" in
            1)
                echo ""
                read -p "  Enter Username: " u
                [[ -z "$u" ]] && continue
                if id "$u" &>/dev/null; then msg_error "User already exists!"; ui_pause; continue; fi
                read -p "  Enter Password: " p
                [[ -z "$p" ]] && continue
                read -p "  Duration in days (0 for Lifetime) [30]: " d
                d=${d:-30}
                if [[ "$d" == "0" || "${d,,}" == "never" ]]; then
                    exp="Never"
                    useradd -M -s /bin/false "$u"
                    chage -E -1 "$u"
                else
                    exp=$(date -d "+$d days" +%Y-%m-%d)
                    useradd -M -s /bin/false -e "$exp" "$u"
                fi
                read -p "  Concurrency limit (Default: 2): " lim
                lim=${lim:-2}
                read -p "  Bandwidth limit GB (0 = unlimited) [0]: " bw
                bw=${bw:-0}

                echo "$u:$p" | chpasswd
                usermod -U "$u" 2>/dev/null
                echo "$u:$p:$exp:$lim:$bw:" >> "$DB_FILE"

                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))")
                sync_v2ray "$u" "$p" "$u_uuid" "add"

                msg_success "Account generated successfully!"
                draw_user_card "$u" "$p" "$exp" "$lim" "$bw"
                ui_pause
                ;;
            2)
                echo ""
                read -p "  Enter Username to edit: " target
                local record=$(grep "^$target:" "$DB_FILE")
                if [[ -z "$record" ]]; then msg_error "User not found!"; ui_pause; continue; fi
                IFS=: read -r cur_u cur_p cur_exp cur_lim cur_bw _rest <<< "$record"
                
                read -p "  New Password [Enter to keep]: " np
                np=${np:-$cur_p}
                read -p "  New Concurrency Limit [Enter to keep]: " nlim
                nlim=${nlim:-$cur_lim}
                read -p "  New Bandwidth GB [Enter to keep]: " nbw
                nbw=${nbw:-$cur_bw}
                read -p "  New Duration in days (0 for Lifetime): " nd
                
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

                msg_success "Account updated successfully."
                draw_user_card "$target" "$np" "$nexp" "$nlim" "$nbw"
                ui_pause
                ;;
            3)
                echo ""
                printf "  ${C_CYAN}%-16s | %-16s | %-12s | %-8s | %-10s${C_RESET}\n" "USERNAME" "PASSWORD" "EXPIRY" "LIMIT" "QUOTA"
                draw_divider
                while IFS=: read -r u p exp lim bw _rest; do
                    [[ -z "$u" || "$u" =~ ^# ]] && continue
                    printf "  %-16s | %-16s | %-12s | %-8s | %-10s\n" "$u" "$p" "$exp" "$lim" "$([ "$bw" == "0" ] && echo "Unlimited" || echo "$bw GB")"
                done < "$DB_FILE"
                ui_pause
                ;;
            4)
                echo ""
                read -p "  Enter Username: " target
                local record=$(grep "^$target:" "$DB_FILE")
                if [[ -z "$record" ]]; then msg_error "User not found!"; ui_pause; continue; fi
                IFS=: read -r u p exp lim bw _rest <<< "$record"
                draw_user_card "$u" "$p" "$exp" "$lim" "$bw"
                ui_pause
                ;;
            5)
                echo ""
                read -p "  Enter Username to delete: " target
                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$target')))")
                userdel -f "$target" 2>/dev/null
                sed -i "/^$target:/d" "$DB_FILE"
                sync_v2ray "$target" "" "$u_uuid" "delete"
                msg_success "User purged completely."
                ui_pause
                ;;
            0) break ;;
        esac
    done
}

menu_protocols() {
    while true; do
        draw_banner
        draw_category_header "CORE NETWORK & PROTOCOLS"
        render_btn "1" "Core Services Health" "(Real-Time Status)"
        render_btn "2" "Reboot All Protocols" "(SSH, V2Ray, Nginx, WS)"
        render_btn "3" "BadVPN 7300 Gateway"  "(Status / Diagnostics)"
        render_btn "4" "UDP Custom Service"   "(Status / State)"
        render_btn "5" "SlowDNS (DNSTT)"      "(Status & Public Key)"
        render_back_btn "Back to Main Dashboard"
        
        echo ""
        read -p "  Action: " opt
        case "$opt" in
            1)
                echo ""
                printf "  %-25s : " "SSH Daemon (Port 22)"
                systemctl is-active --quiet ssh && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "WS Bridge (Port 10015)"
                systemctl is-active --quiet ws-dropbear && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "V2Ray Multi-Engine"
                systemctl is-active --quiet v2ray && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "Nginx Edge Proxy (443)"
                systemctl is-active --quiet nginx && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "BadVPN UDP Gateway"
                systemctl is-active --quiet badvpn && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "UDP Custom Core"
                systemctl is-active --quiet udp-custom && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                printf "  %-25s : " "DNSTT SlowDNS (Port 53)"
                systemctl is-active --quiet dnstt && echo -e "${C_GREEN}RUNNING${C_RESET}" || echo -e "${C_RED}STOPPED${C_RESET}"
                ui_pause
                ;;
            2)
                systemctl restart ssh ws-dropbear v2ray nginx badvpn udp-custom dnstt 2>/dev/null || true
                msg_success "All network protocol services restarted."
                ui_pause
                ;;
            3)
                systemctl status badvpn --no-pager | head -n 12
                ui_pause
                ;;
            4)
                systemctl status udp-custom --no-pager | head -n 12
                ui_pause
                ;;
            5)
                local pub_key=$([ -f "/etc/ssh-manager/dnstt/server.pub" ] && cat "/etc/ssh-manager/dnstt/server.pub" || echo "Not_Found")
                msg_info "DNSTT Public Key: $pub_key"
                systemctl status dnstt --no-pager | head -n 12
                ui_pause
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
        msg_info "Uninstall canceled."
        ui_pause
        return
    fi

    echo -e "\n${C_RED}[*] Stopping services...${C_RESET}"
    systemctl stop nginx v2ray badvpn udp-custom dnstt ws-dropbear haproxy 2>/dev/null || true
    systemctl disable nginx v2ray badvpn udp-custom dnstt ws-dropbear haproxy 2>/dev/null || true

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

    rm -rf /etc/ssh-manager /usr/local/etc/v2ray /etc/v2ray /root/udp /etc/nginx /etc/letsencrypt
    rm -f /usr/local/bin/ssh-manager /usr/local/bin/menu* /bin/menu /usr/local/bin/badvpn-udpgw /usr/local/bin/udp-custom /usr/local/bin/dnstt-server /usr/local/bin/ws-dropbear /usr/local/bin/session-watchdog
    rm -f /etc/systemd/system/badvpn.service /etc/systemd/system/udp-custom.service /etc/systemd/system/dnstt.service /etc/systemd/system/ws-dropbear.service
    systemctl daemon-reload

    msg_success "SSH-MANAGER has been completely removed from system."
    exit 0
}

menu_settings() {
    while true; do
        draw_banner
        draw_category_header "SYSTEM & ADVANCED"
        render_btn "1" "Update Pointing Domain" "(Reconfigure Host)"
        render_btn "2" "Update NS Domain"       "(SlowDNS Nameserver)"
        render_btn "3" "Renew SSL Certificate" "(Let's Encrypt / Certbot)"
        render_btn "4" "Purge & Uninstall All"  "(Delete All Files & Reset)"
        render_back_btn "Back to Main Dashboard"
        
        echo ""
        read -p "  Action: " opt
        case "$opt" in
            1)
                read -p "  Enter new domain: " ndom
                [[ -n "$ndom" ]] && echo "$ndom" > "$DOMAIN_FILE"
                msg_success "Domain updated."
                ui_pause
                ;;
            2)
                read -p "  Enter new NS domain: " nns
                [[ -n "$nns" ]] && echo "$nns" > "$NS_FILE"
                systemctl restart dnstt 2>/dev/null || true
                msg_success "NS updated."
                ui_pause
                ;;
            3)
                systemctl stop nginx
                certbot renew --quiet
                systemctl start nginx
                msg_success "SSL Certificate renewed."
                ui_pause
                ;;
            4) uninstall_all ;;
            0) break ;;
        esac
    done
}

while true; do
    draw_banner
    draw_category_header "MAIN CONTROL DASHBOARD"
    render_btn "1" "User & Account Control"  "(Add, Lifetime, Quota, Limits)"
    render_btn "2" "Protocol & Server Suite" "(SSH-WS, Trojan, VMess, UDP, DNSTT)"
    render_btn "3" "System & Security Tools" "(Domain, SSL, Uninstall)"
    render_btn "4" "Active Sessions Monitor" "(Live Online SSH Connections)"
    render_back_btn "Exit Interface"
    
    echo ""
    read -p "  Select [0-4]: " mc
    case "$mc" in
        1) menu_users ;;
        2) menu_protocols ;;
        3) menu_settings ;;
        4)
            draw_banner
            draw_category_header "CURRENT LIVE SESSIONS"
            who
            echo ""
            ss -tp '( sport = :22 or sport = :443 )' | head -n 15
            ui_pause
            ;;
        0) clear; exit 0 ;;
    esac
done
