#!/bin/bash
export LC_ALL=C
clear

UI_DIR="/etc/ssh-manager/ui"
BASE_UI_URL="https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main/ui"

mkdir -p "$UI_DIR"
for comp in colors banner buttons cards; do
    if [ ! -f "$UI_DIR/$comp.sh" ]; then
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
' "$u" "$p" "$uuid" "$action" 2>/dev/null || true
    systemctl restart v2ray 2>/dev/null || true
}

# دالة مدمجة لعرض جدول المستخدمين في أي شاشة
display_users_table() {
    echo -e "  ${C_BOLD}${C_YELLOW}Active Users Database:${C_RESET}"
    if [ ! -s "$DB_FILE" ]; then
        echo -e "  ${C_GRAY}(No active accounts found)${C_RESET}"
    else
        printf "  ${C_CYAN}%-12s | %-10s | %-8s | %-5s${C_RESET}\n" "USER" "EXPIRY" "LIMIT" "PASS"
        echo -e "  ${C_GRAY}────────────────────────────────────────${C_RESET}"
        while IFS=: read -r u p exp lim bw _; do
            [[ -z "$u" || "$u" =~ ^# ]] && continue
            printf "  %-12s | %-10s | %-8s | %-5s\n" "$u" "$exp" "$lim Dev" "$p"
        done < "$DB_FILE"
    fi
    echo -e "  ${C_GRAY}────────────────────────────────────────${C_RESET}"
}

update_script() {
    printf "\033[2J\033[3J\033[H"
    echo -e "\n  ${C_CYAN}[*] Fetching latest updates from GitHub...${C_RESET}"
    
    local REPO_URL="https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main"
    
    for comp in colors banner buttons cards; do
        curl -fsSL -o "/etc/ssh-manager/ui/$comp.sh" "$REPO_URL/ui/$comp.sh" 2>/dev/null || true
        chmod +x "/etc/ssh-manager/ui/$comp.sh" 2>/dev/null || true
    done
    
    curl -fsSL -o /usr/local/bin/ssh-manager "$REPO_URL/menu.sh" 2>/dev/null || true
    chmod +x /usr/local/bin/ssh-manager
    ln -sf /usr/local/bin/ssh-manager /usr/local/bin/menu
    ln -sf /usr/local/bin/ssh-manager /bin/menu
    
    msg_ok "Script and UI updated successfully!"
    ui_pause
    exec menu
}

purge_everything() {
    printf "\033[2J\033[3J\033[H"
    echo -e "${C_RED}"
    echo "=========================================="
    echo "       COMPLETE UNINSTALL & PURGE         "
    echo "=========================================="
    echo -e "${C_RESET}"
    read -p "Type 'DELETE' to erase everything: " confirm
    if [ "$confirm" != "DELETE" ]; then
        msg_err "Uninstall canceled."
        ui_pause
        return
    fi

    echo -e "\n${C_RED}[*] Stopping and disabling all services...${C_RESET}"
    systemctl stop nginx apache2 v2ray badvpn udp-custom dnstt ws-dropbear 2>/dev/null
    systemctl disable nginx apache2 v2ray badvpn udp-custom dnstt ws-dropbear 2>/dev/null

    pkill -9 -f badvpn 2>/dev/null
    pkill -9 -f udp-custom 2>/dev/null
    pkill -9 -f dnstt-server 2>/dev/null
    pkill -9 -f v2ray 2>/dev/null
    pkill -9 -f ws-dropbear 2>/dev/null
    fuser -k 80/tcp 443/tcp 53/udp 7300/udp 10015/tcp 2>/dev/null

    echo -e "${C_RED}[*] Clearing Cron Jobs...${C_RESET}"
    crontab -r 2>/dev/null || true

    echo -e "${C_RED}[*] Deleting all created users...${C_RESET}"
    if [ -f "$DB_FILE" ]; then
        while IFS=: read -r u _rest; do
            [[ -n "$u" && ! "$u" =~ ^# ]] && userdel -f "$u" 2>/dev/null
        done < "$DB_FILE"
    fi

    echo -e "${C_RED}[*] Purging system packages...${C_RESET}"
    apt-get purge -y nginx nginx-common v2ray certbot python3-certbot-nginx 2>/dev/null
    apt-get autoremove -y --purge 2>/dev/null

    echo -e "${C_RED}[*] Erasing directories, binaries & services...${C_RESET}"
    rm -rf /etc/ssh-manager /usr/local/etc/v2ray /etc/v2ray /root/udp /etc/nginx /etc/letsencrypt
    rm -f /usr/local/bin/ssh-manager /usr/local/bin/menu* /bin/menu /usr/local/bin/badvpn-udpgw /usr/local/bin/udp-custom /usr/local/bin/dnstt-server /usr/local/bin/ws-dropbear /usr/local/bin/session-watchdog
    rm -f /etc/systemd/system/badvpn.service /etc/systemd/system/udp-custom.service /etc/systemd/system/dnstt.service /etc/systemd/system/ws-dropbear.service
    systemctl daemon-reload

    unalias menu 2>/dev/null || true
    sed -i '/menu/d' ~/.bashrc /root/.bashrc /etc/bash.bashrc /etc/profile /etc/environment 2>/dev/null || true
    hash -r

    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
    echo -e "\n${C_GREEN}✔ SSH-MANAGER has been completely wiped from your server!${C_RESET}\n"
    exit 0
}

menu_users() {
    while true; do
        draw_banner
        draw_section "USER MANAGEMENT"
        
        # ظهور جدول الحسابات تلقائياً في واجهة إدارة المستخدمين
        display_users_table
        echo ""

        render_btn "1" "Create New Account"
        render_btn "2" "Edit Account (Pass/Limit/Expiry)"
        render_btn "3" "Get Account Credentials Card"
        render_btn "4" "Delete Single User"
        render_danger_btn "5" "Delete ALL Users (Purge Accounts)"
        render_btn "0" "Back to Dashboard"
        
        echo ""
        read -p "  Select: " opt
        case "$opt" in
            1)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "CREATE NEW ACCOUNT"
                read -p "  Username: " u
                [[ -z "$u" ]] && continue
                if id "$u" &>/dev/null; then msg_err "User exists!"; ui_pause; continue; fi
                read -p "  Password: " p
                [[ -z "$p" ]] && continue
                read -p "  Days (0 for Lifetime) [30]: " d
                d=${d:-30}
                if [[ "$d" == "0" || "${d,,}" == "never" ]]; then
                    exp="Never"
                    useradd -M -s /bin/false "$u"
                    chage -E -1 "$u"
                else
                    exp=$(date -d "+$d days" +%Y-%m-%d)
                    useradd -M -s /bin/false -e "$exp" "$u"
                fi
                read -p "  Limit Devices [2]: " lim
                lim=${lim:-2}
                read -p "  Bandwidth GB (0=Unlimited) [0]: " bw
                bw=${bw:-0}

                echo "$u:$p" | chpasswd
                usermod -U "$u" 2>/dev/null
                echo "$u:$p:$exp:$lim:$bw:" >> "$DB_FILE"

                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))" 2>/dev/null || echo "none")
                sync_v2ray "$u" "$p" "$u_uuid" "add"

                draw_user_card "$u" "$p" "$exp" "$lim" "$bw"
                ui_pause
                ;;
            2)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "EDIT ACCOUNT"
                display_users_table
                echo ""
                read -p "  Username to edit: " target
                [[ -z "$target" ]] && continue
                local rec=$(grep "^$target:" "$DB_FILE")
                if [[ -z "$rec" ]]; then msg_err "User not found!"; ui_pause; continue; fi
                IFS=: read -r cur_u cur_p cur_exp cur_lim cur_bw _rest <<< "$rec"

                read -p "  New Pass [Enter=Keep]: " np
                np=${np:-$cur_p}
                read -p "  New Limit [Enter=Keep]: " nlim
                nlim=${nlim:-$cur_lim}
                read -p "  New Bandwidth GB [Enter=Keep]: " nbw
                nbw=${nbw:-$cur_bw}
                read -p "  Days (0=Lifetime) [Enter=Keep]: " nd

                nexp="$cur_exp"
                if [[ "$nd" == "0" || "${nd,,}" == "never" ]]; then
                    nexp="Never"; chage -E -1 "$target"
                elif [[ -n "$nd" && "$nd" =~ ^[0-9]+$ ]]; then
                    nexp=$(date -d "+$nd days" +%Y-%m-%d); usermod -e "$nexp" "$target"
                fi

                echo "$target:$np" | chpasswd
                sed -i "/^$target:/d" "$DB_FILE"
                echo "$target:$np:$nexp:$nlim:$nbw:" >> "$DB_FILE"

                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$target')))" 2>/dev/null || echo "none")
                sync_v2ray "$target" "$np" "$u_uuid" "update"

                msg_ok "Account updated."
                draw_user_card "$target" "$np" "$nexp" "$nlim" "$nbw"
                ui_pause
                ;;
            3)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "ACCOUNT DETAILS & LINKS"
                display_users_table
                echo ""
                read -p "  Username: " target
                [[ -z "$target" ]] && continue
                local rec=$(grep "^$target:" "$DB_FILE")
                if [[ -z "$rec" ]]; then msg_err "Not found!"; ui_pause; continue; fi
                IFS=: read -r u p exp lim bw _rest <<< "$rec"
                draw_user_card "$u" "$p" "$exp" "$lim" "$bw"
                ui_pause
                ;;
            4)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "DELETE USER"
                display_users_table
                echo ""
                read -p "  Username to delete: " target
                [[ -z "$target" ]] && continue
                local rec=$(grep "^$target:" "$DB_FILE")
                if [[ -z "$rec" ]]; then msg_err "User not found!"; ui_pause; continue; fi
                
                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$target')))" 2>/dev/null || echo "none")
                userdel -f "$target" 2>/dev/null
                sed -i "/^$target:/d" "$DB_FILE"
                sync_v2ray "$target" "" "$u_uuid" "delete"
                msg_ok "User '$target' deleted successfully."
                ui_pause
                ;;
            5)
                printf "\033[2J\033[3J\033[H"
                echo -e "${C_RED}"
                echo "=========================================="
                echo "         DELETE ALL USERS CONFIRM         "
                echo "=========================================="
                echo -e "${C_RESET}"
                display_users_table
                echo ""
                read -p "Type 'CONFIRM' to delete ALL users: " all_confirm
                if [ "$all_confirm" = "CONFIRM" ]; then
                    while IFS=: read -r u _rest; do
                        [[ -n "$u" && ! "$u" =~ ^# ]] && userdel -f "$u" 2>/dev/null
                    done < "$DB_FILE"
                    > "$DB_FILE"
                    
                    # تصفير عملاء V2Ray
                    python3 -c '
import json
path = "/usr/local/etc/v2ray/config.json"
try:
    with open(path, "r") as f: cfg = json.load(f)
    for ib in cfg.get("inbounds", []):
        ib["settings"]["clients"] = []
    with open(path, "w") as f: json.dump(cfg, f, indent=2)
except Exception: pass
' 2>/dev/null || true
                    systemctl restart v2ray 2>/dev/null || true
                    msg_ok "All users deleted and database cleared."
                else
                    msg_err "Action aborted."
                fi
                ui_pause
                ;;
            0) break ;;
        esac
    done
}

while true; do
    draw_banner
    draw_section "MAIN CONTROL HUB"
    render_btn "1" "User Account Manager"
    render_btn "2" "Restart All Services"
    render_btn "3" "Change Domain"
    render_btn "4" "Active Live Sessions"
    render_btn "8" "Update Script"
    render_danger_btn "9" "UNINSTALL & PURGE ALL"
    render_btn "0" "Exit"

    echo ""
    read -p "  Select [0-9]: " mc
    case "$mc" in
        1) menu_users ;;
        2)
            systemctl restart ssh ws-dropbear v2ray nginx badvpn udp-custom dnstt 2>/dev/null || true
            msg_ok "Services refreshed."
            ui_pause
            ;;
        3)
            read -p "  Enter new domain: " ndom
            [[ -n "$ndom" ]] && echo "$ndom" > "$DOMAIN_FILE"
            msg_ok "Domain updated."
            ui_pause
            ;;
        4)
            draw_banner
            draw_section "LIVE SESSIONS"
            who
            echo ""
            ss -tp '( sport = :22 or sport = :443 )' | head -n 10
            ui_pause
            ;;
        8) update_script ;;
        9) purge_everything ;;
        0) printf "\033[2J\033[3J\033[H"; exit 0 ;;
    esac
done
