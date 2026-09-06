#!/bin/bash
export LC_ALL=C

draw_section() {
    local title="$1"
    echo -e "\n  ${C_BOLD}${C_YELLOW}▶ $title${C_RESET}"
    echo -e "  ${C_GRAY}──────────────────────────────────────${C_RESET}"
}

render_btn() {
    local key="$1"
    local title="$2"
    printf "  ${C_CYAN}[ ${C_BOLD}%s${C_RESET}${C_CYAN} ]${C_RE#!/bin/bash
export LC_ALL=C

draw_section() {
    local title="$1"
    echo -e "\n  ${C_BOLD}${C_YELLOW}▶ $title${C_RESET}"
    echo -e "  ${C_GRAY}────────────────────────────────────────${C_RESET}"
}

render_btn() {
    local key="$1"
    local title="$2"
    printf "  ${C_CYAN}[ ${C_BOLD}%s${C_RESET}${C_CYAN} ]${C_RESET}  ${C_BOLD}%s${C_RESET}\n" "$key" "$title"
}

render_danger_btn() {
    local key="$1"
    local title="$2"
    printf "  ${C_RED}[ ${C_BOLD}%s${C_RESET}${C_RED} ]  %s${C_RESET}\n" "$key" "$title"
}

ui_pause() {
    echo ""
    read -p "  [Press Enter to continue]" _
    printf "\033[2J\033[3J\033[H"
}

# دالة عرض المستخدمين المرقمة مع فحص الجلسات الحية
select_user_by_number() {
    USERS_LIST=()
    local db="/etc/ssh-manager/users.db"
    if [ ! -s "$db" ]; then
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
    done < "$db"
    echo -e "  ${C_GRAY}────────────────────────────────────────${C_RESET}"
    return 0
}SET}  ${C_BOLD}%s${C_RESET}\n" "$key" "$title"
}

render_danger_btn() {
    local key="$1"
    local title="$2"
    printf "  ${C_RED}[ ${C_BOLD}%s${C_RESET}${C_RED} ]  %s${C_RESET}\n" "$key" "$title"
}

msg_ok() {
    echo -e "\n  ${C_GREEN}✔ $1${C_RESET}"
}

msg_err() {
    echo -e "\n  ${C_RED}✖ $1${C_RESET}"
}

ui_pause() {
    echo ""
    read -p "  [Press Enter to continue]" _
    # تنظيف فوري عند المتابعة
    printf "\033[2J\033[3J\033[H"
}
