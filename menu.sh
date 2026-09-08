#!/bin/bash
export LC_ALL=C
clear

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_CYAN="\033[38;5;51m"
C_BLUE="\033[38;5;39m"
C_PURPLE="\033[38;5;141m"
C_GREEN="\033[38;5;48m"
C_YELLOW="\033[38;5;220m"
C_RED="\033[38;5;196m"
C_GRAY="\033[38;5;244m"

DB_FILE="/etc/ssh-manager/users.db"
DOMAIN_FILE="/etc/ssh-manager/domain.conf"
UI_DIR="/etc/ssh-manager/ui"
BASE_UI_URL="https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main/ui"

mkdir -p /etc/ssh-manager "$UI_DIR"
touch "$DB_FILE"
[ ! -f "$DOMAIN_FILE" ] && echo "127.0.0.1" > "$DOMAIN_FILE"

# Ensure UI files exist
for comp in colors banner buttons cards; do
    if [ ! -f "$UI_DIR/$comp.sh" ]; then
        curl -fsSL -o "$UI_DIR/$comp.sh" "$BASE_UI_URL/$comp.sh" 2>/dev/null
        chmod +x "$UI_DIR/$comp.sh" 2>/dev/null
    fi
    [ -s "$UI_DIR/$comp.sh" ] && source "$UI_DIR/$comp.sh" 2>/dev/null
done

# Check and enforce SSH authentication overrides silently
fix_auth_services() {
    mkdir -p /etc/ssh/sshd_config.d
    if [ ! -f /etc/ssh/sshd_config.d/00-override.conf ]; then
        cat << 'EOF' > /etc/ssh/sshd_config.d/00-override.conf
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PubkeyAuthentication yes
UsePAM yes
AuthenticationMethods password publickey,password keyboard-interactive
EOF
        systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
    fi
}
fix_auth_services

draw_section() {
    echo -e "\n  ${C_BOLD}${C_YELLOW}▶ $1${C_RESET}"
    echo -e "  ${C_GRAY}────────────────────────────────────────${C_RESET}"
}

render_btn() {
    printf "  ${C_CYAN}[ ${C_BOLD}%s${C_RESET}${C_CYAN} ]${C_RESET}  ${C_BOLD}%s${C_RESET}\n" "$1" "$2"
}

render_danger_btn() {
    printf "  ${C_RED}[ ${C_BOLD}%s${C_RESET}${C_RED} ]  %s${C_RESET}\n" "$1" "$2"
}

ui_pause() {
    echo ""
    read -p "  [Press Enter to continue]" _
    printf "\033[2J\033[3J\033[H"
}

draw_banner() {
    printf "\033[2J\033[3J\033[H"
    local cur_dom="127.0.0.1"
    [ -f "$DOMAIN_FILE" ] && cur_dom=$(cat "$DOMAIN_FILE")

    local cpu_load=$(top -bn1 2>/dev/null | awk -F',' '/Cpu\(s\)/ {print $1}' | awk '{print $2}' || echo "0.0")
    local mem_used=$(free -m 2>/dev/null | awk '/Mem:/ {print $3}' || echo "0")
    local mem_total=$(free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo "1")
    local mem_pct=$(( mem_used * 100 / (mem_total > 0 ? mem_total : 1) ))
    local s_up=$(uptime -p 2>/dev/null | sed -e 's/up //' -e 's/ hours\?/h/' -e 's/ minutes\?/m/' || echo "N/A")
    local online_ssh=$(who 2>/dev/null | wc -l)
    local total_accs=$(grep -c . "$DB_FILE" 2>/dev/null || echo "0")

    local s_ssh="●"; systemctl is-active --quiet ssh && s_ssh="${C_GREEN}●${C_RESET}" || s_ssh="${C_RED}●${C_RESET}"
    local s_ws="●"; systemctl is-active --quiet ws-dropbear && s_ws="${C_GREEN}●${C_RESET}" || s_ws="${C_RED}●${C_RESET}"
    local s_v2r="●"; systemctl is-active --quiet v2ray && s_v2r="${C_GREEN}●${C_RESET}" || s_v2r="${C_RED}●${C_RESET}"
    local s_ngx="●"; systemctl is-active --quiet nginx && s_ngx="${C_GREEN}●${C_RESET}" || s_ngx="${C_RED}●${C_RESET}"
    local s_udp="●"; systemctl is-active --quiet udp-custom && s_udp="${C_GREEN}●${C_RESET}" || s_udp="${C_RED}●${C_RESET}"
    local s_dns="●"; systemctl is-active --quiet dnstt && s_dns="${C_GREEN}●${C_RESET}" || s_dns="${C_RED}●${C_RESET}"

    echo -e "${C_CYAN}┌────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET}        ${C_BOLD}${C_YELLOW}SSH-MANAGER BY-AZDIN${C_RESET}            ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}├────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET} ${C_BOLD}TASK MANAGER (LIVE)${C_RESET}                   ${C_CYAN}│${C_RESET}"
    printf "${C_CYAN}│${C_RESET} CPU: ${C_YELLOW}%-5s${C_RESET} | RAM: ${C_YELLOW}%s/%sMB (%s%%)${C_RESET}  ${C_CYAN}│${C_RESET}\n" "${cpu_load}%" "$mem_used" "$mem_total" "$mem_pct"
    printf "${C_CYAN}│${C_RESET} UP : ${C_GREEN}%-6s${C_RESET} | ONLINE: ${C_GREEN}%-2s${C_RESET} | USERS: ${C_GREEN}%-3s${C_RESET} ${C_CYAN}│${C_RESET}\n" "$s_up" "$online_ssh" "$total_accs"
    echo -e "${C_CYAN}├────────────────────────────────────────┤${C_RESET}"
    printf "${C_CYAN}│${C_RESET} SRV: SSH:%b WS:%b V2R:%b NGX:%b UDP:%b DNS:%b ${C_CYAN}│${C_RESET}\n" "$s_ssh" "$s_ws" "$s_v2r" "$s_ngx" "$s_udp" "$s_dns"
    printf "${C_CYAN}│${C_RESET} DOM: ${C_PURPLE}%-33s${C_RESET} ${C_CYAN}│${C_RESET}\n" "$cur_dom"
    echo -e "${C_CYAN}└────────────────────────────────────────┘${C_RESET}"
}

select_user_by_number() {
    USERS_LIST=()
    if [ ! -s "$DB_FILE" ]; then
        echo -e "  ${C_GRAY}(No active accounts found)${C_RESET}"
        return 1
    fi

    printf "  ${C_CYAN}%-4s %-12s %-16s %-10s${C_RESET}\n" "NUM" "USER" "STATUS (LIVE)" "EXPIRY"
    echo -e "  ${C_GRAY}────────────────────────────────────────${C_RESET}"

    local count=1
    while IFS=: read -r u p exp lim bw _; do
        [[ -z "$u" || "$u" =~ ^# ]] && continue
        USERS_LIST+=("$u")
        local act_sess=$(ps -u "$u" -o comm= 2>/dev/null | grep -E '^(sshd|dropbear)$' | wc -l)
        local status_str
        if [ "$act_sess" -gt 0 ]; then
            status_str="${C_GREEN}ONLINE ($act_sess/$lim)${C_RESET}"
        else
            status_str="${C_GRAY}OFFLINE (0/$lim)${C_RESET}"
        fi
        printf "  ${C_YELLOW}[%2d]${C_RESET} %-12s %-25b %-10s\n" "$count" "$u" "$status_str" "$exp"
        ((count++))
    done < "$DB_FILE"
    echo -e "  ${C_GRAY}────────────────────────────────────────${C_RESET}"
    return 0
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
' "$u" "$p" "$uuid" "$action" 2>/dev/null || true
    systemctl restart v2ray 2>/dev/null || true
}

ensure_dnstt_service() {
    local dom=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "127.0.0.1")
    if [ ! -f /usr/local/bin/dnstt-server ] || [ ! -f /etc/systemd/system/dnstt.service ]; then
        mkdir -p /etc/slowdns
        ARCH=$(uname -m)
        [ "$ARCH" = "aarch64" ] && D_ARCH="arm64" || D_ARCH="amd64"
        curl -fsSL -o /usr/local/bin/dnstt-server "https://github.com/cbeuw/dnstt/releases/latest/download/dnstt-server-linux-${D_ARCH}" 2>/dev/null
        chmod +x /usr/local/bin/dnstt-server

        [ ! -f /etc/slowdns/server.key ] && /usr/local/bin/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub 2>/dev/null || true

        cat << EOF > /etc/systemd/system/dnstt.service
[Unit]
Description=SlowDNS (DNSTT) Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key ns.${dom} 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable dnstt 2>/dev/null || true
    fi
}

menu_users() {
    while true; do
        draw_banner
        draw_section "USER MANAGEMENT"
        render_btn "1" "Create New Account"
        render_btn "2" "Edit User (By Number)"
        render_btn "3" "Get User Credentials (By Number)"
        render_btn "4" "Delete Single User (By Number)"
        render_danger_btn "5" "Delete ALL Users"
        render_btn "0" "Back to Dashboard"

        echo ""
        read -p "  Select: " opt
        case "$opt" in
            1)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "CREATE ACCOUNT"
                read -p "  Username: " u
                [[ -z "$u" ]] && continue
                if id "$u" &>/dev/null; then echo -e "  ${C_RED}User exists!${C_RESET}"; ui_pause; continue; fi
                read -p "  Password: " p
                [[ -z "$p" ]] && continue
                read -p "  Days (0 for Lifetime) [30]: " d
                d=${d:-30}

                # Universal system account creation
                useradd -M -s /bin/false "$u" 2>/dev/null || useradd -m -s /bin/false "$u"
                if [[ "$d" == "0" || "${d,,}" == "never" ]]; then
                    exp="Never"
                    chage -E -1 "$u" 2>/dev/null || true
                else
                    exp=$(date -d "+$d days" +%Y-%m-%d)
                    usermod -e "$exp" "$u" 2>/dev/null || true
                fi
                chage -I -1 "$u" 2>/dev/null || true
                chage -m 0 "$u" 2>/dev/null || true
                chage -M 99999 "$u" 2>/dev/null || true

                echo "$u:$p" | chpasswd
                usermod -p "$(openssl passwd -1 "$p")" "$u" 2>/dev/null || true
                passwd -u "$u" 2>/dev/null || true

                read -p "  Limit Devices [2]: " lim
                lim=${lim:-2}
                read -p "  Bandwidth GB (0=Unlim) [0]: " bw
                bw=${bw:-0}

                echo "$u:$p:$exp:$lim:$bw:" >> "$DB_FILE"
                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$u')))" 2>/dev/null || echo "none")
                sync_v2ray "$u" "$p" "$u_uuid" "add"

                declare -f draw_user_card >/dev/null && draw_user_card "$u" "$p" "$exp" "$lim" "$bw"
                ui_pause
                ;;
            2)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "EDIT ACCOUNT"
                select_user_by_number || { ui_pause; continue; }
                echo ""
                read -p "  Select user number: " unum
                [[ -z "$unum" || ! "$unum" =~ ^[0-9]+$ ]] && continue
                local target="${USERS_LIST[$((unum-1))]}"
                if [[ -z "$target" ]]; then echo -e "  ${C_RED}Invalid selection!${C_RESET}"; ui_pause; continue; fi

                local rec=$(grep "^$target:" "$DB_FILE")
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
                    nexp="Never"; chage -E -1 "$target" 2>/dev/null || true
                elif [[ -n "$nd" && "$nd" =~ ^[0-9]+$ ]]; then
                    nexp=$(date -d "+$nd days" +%Y-%m-%d); usermod -e "$nexp" "$target" 2>/dev/null || true
                fi

                echo "$target:$np" | chpasswd
                usermod -p "$(openssl passwd -1 "$np")" "$target" 2>/dev/null || true
                passwd -u "$target" 2>/dev/null || true

                sed -i "/^$target:/d" "$DB_FILE"
                echo "$target:$np:$nexp:$nlim:$nbw:" >> "$DB_FILE"
                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$target')))" 2>/dev/null || echo "none")
                sync_v2ray "$target" "$np" "$u_uuid" "update"

                echo -e "  ${C_GREEN}✔ Updated.${C_RESET}"
                declare -f draw_user_card >/dev/null && draw_user_card "$target" "$np" "$nexp" "$nlim" "$nbw"
                ui_pause
                ;;
            3)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "GET CREDENTIALS"
                select_user_by_number || { ui_pause; continue; }
                echo ""
                read -p "  Select user number: " unum
                [[ -z "$unum" || ! "$unum" =~ ^[0-9]+$ ]] && continue
                local target="${USERS_LIST[$((unum-1))]}"
                if [[ -z "$target" ]]; then echo -e "  ${C_RED}Invalid selection!${C_RESET}"; ui_pause; continue; fi
                IFS=: read -r u p exp lim bw _rest <<< "$(grep "^$target:" "$DB_FILE")"
                declare -f draw_user_card >/dev/null && draw_user_card "$u" "$p" "$exp" "$lim" "$bw"
                ui_pause
                ;;
            4)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "DELETE USER"
                select_user_by_number || { ui_pause; continue; }
                echo ""
                read -p "  Select user number to delete: " unum
                [[ -z "$unum" || ! "$unum" =~ ^[0-9]+$ ]] && continue
                local target="${USERS_LIST[$((unum-1))]}"
                if [[ -z "$target" ]]; then echo -e "  ${C_RED}Invalid selection!${C_RESET}"; ui_pause; continue; fi

                local u_uuid=$(python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_DNS, '$target')))" 2>/dev/null || echo "none")
                userdel -f "$target" 2>/dev/null
                sed -i "/^$target:/d" "$DB_FILE"
                sync_v2ray "$target" "" "$u_uuid" "delete"
                echo -e "  ${C_GREEN}✔ User '$target' deleted.${C_RESET}"
                ui_pause
                ;;
            5)
                printf "\033[2J\033[3J\033[H"
                draw_banner
                draw_section "DELETE ALL USERS"
                select_user_by_number
                echo ""
                read -p "Type 'CONFIRM' to delete ALL accounts: " confirm
                if [ "$confirm" = "CONFIRM" ]; then
                    while IFS=: read -r u _rest; do
                        [[ -n "$u" && ! "$u" =~ ^# ]] && userdel -f "$u" 2>/dev/null
                    done < "$DB_FILE"
                    > "$DB_FILE"
                    python3 -c '
import json
path = "/usr/local/etc/v2ray/config.json"
try:
    with open(path, "r") as f: cfg = json.load(f)
    for ib in cfg.get("inbounds", []): ib["settings"]["clients"] = []
    with open(path, "w") as f: json.dump(cfg, f, indent=2)
except Exception: pass
' 2>/dev/null || true
                    systemctl restart v2ray 2>/dev/null || true
                    echo -e "  ${C_GREEN}✔ All users deleted.${C_RESET}"
                else
                    echo -e "  ${C_RED}Aborted.${C_RESET}"
                fi
                ui_pause
                ;;
            0) break ;;
        esac
    done
}

menu_slowdns() {
    while true; do
        draw_banner
        draw_section "SLOWDNS (DNSTT) CONTROL"
        render_btn "1" "Restart SlowDNS"
        render_btn "2" "Show Public Key"
        render_btn "0" "Back"

        echo ""
        read -p "  Action: " opt
        case "$opt" in
            1)
                ensure_dnstt_service
                systemctl restart dnstt 2>/dev/null
                if systemctl is-active --quiet dnstt; then
                    echo -e "  ${C_GREEN}✔ SlowDNS restarted.${C_RESET}"
                else
                    echo -e "  ${C_RED}✖ SlowDNS service failed to start.${C_RESET}"
                fi
                ui_pause
                ;;
            2)
                echo ""
                if [ -f /etc/slowdns/server.pub ]; then
                    echo -e "  ${C_CYAN}SlowDNS Public Key:${C_RESET}"
                    echo -e "  ${C_YELLOW}$(cat /etc/slowdns/server.pub)${C_RESET}"
                else
                    echo -e "  ${C_RED}Key not found! Generating...${C_RESET}"
                    ensure_dnstt_service
                    cat /etc/slowdns/server.pub 2>/dev/null || echo -e "  ${C_RED}Failed to locate key.${C_RESET}"
                fi
                ui_pause
                ;;
            0) break ;;
        esac
    done
}

menu_protocols() {
    while true; do
        draw_banner
        draw_section "PROTOCOLS & SERVICES"
        render_btn "1" "SlowDNS (DNSTT) Manager"
        render_btn "2" "Restart SSH & Dropbear"
        render_btn "3" "Restart V2Ray Services"
        render_btn "0" "Back"

        echo ""
        read -p "  Select: " psel
        case "$psel" in
            1) menu_slowdns ;;
            2)
                systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
                systemctl restart dropbear 2>/dev/null || true
                systemctl restart ws-dropbear 2>/dev/null || true
                echo -e "  ${C_GREEN}✔ SSH and Dropbear services restarted.${C_RESET}"
                ui_pause
                ;;
            3)
                systemctl restart v2ray 2>/dev/null || true
                systemctl restart nginx 2>/dev/null || true
                echo -e "  ${C_GREEN}✔ V2Ray & Nginx restarted.${C_RESET}"
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
    render_btn "2" "Protocols & Services Suite"
    render_btn "3" "Change Domain"
    render_btn "4" "Active Live Sessions"
    render_btn "0" "Exit"

    echo ""
    read -p "  Select [0-4]: " mc
    case "$mc" in
        1) menu_users ;;
        2) menu_protocols ;;
        3)
            read -p "  Enter new domain: " ndom
            if [[ -n "$ndom" ]]; then
                echo "$ndom" > "$DOMAIN_FILE"
                ensure_dnstt_service
                systemctl restart dnstt 2>/dev/null || true
                echo -e "  ${C_GREEN}✔ Domain updated.${C_RESET}"
            fi
            ui_pause
            ;;
        4)
            draw_banner
            draw_section "LIVE SESSIONS"
            who
            echo ""
            ss -tp '( sport = :22 or sport = :443 )' 2>/dev/null | head -n 10
            ui_pause
            ;;
        0) printf "\033[2J\033[3J\033[H"; exit 0 ;;
    esac
done
