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
    printf "  ${C_CYAN}[ ${C_BOLD}%s${C_RESET}${C_CYAN} ]${C_RESET}  ${C_BOLD}%s${C_RESET}\n" "$key" "$title"
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
