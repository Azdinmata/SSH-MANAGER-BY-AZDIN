#!/bin/bash
export LC_ALL=C

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
        
        local act_sess
        act_sess=$(ps -u "$u" -o comm= 2>/dev/null | grep -E '^(sshd|dropbear)$' | wc -l)
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
}
