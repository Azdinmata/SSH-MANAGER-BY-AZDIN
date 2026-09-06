#!/bin/bash
# ========================================================
# UI THEME: BUTTONS, LABELS & INPUT PROMPTS
# ========================================================

draw_category_header() {
    local title="$1"
    echo -e "\n  ${C_BOLD}${C_YELLOW}╔══[ $title ]${C_RESET}\n"
}

# شكل أزرار الاختيار
btn() {
    local num="$1"
    local text="$2"
    local desc="$3"
    printf "  ${C_CYAN}⟦${C_BOLD}%s${C_RESET}${C_CYAN}⟧${C_RESET} %-30s ${C_GRAY}%s${C_RESET}\n" "$num" "$text" "$desc"
}

# زر التراجع أو الخروج
btn_back() {
    local text="${1:-Back / Exit}"
    echo -e "\n  ${C_RED}⟦0⟧${C_RESET} ${C_BOLD}$text${C_RESET}"
}

# شريط الفاصل البسيط
divider() {
    echo -e "  ${C_GRAY}────────────────────────────────────────────────────────────────────────${C_RESET}"
}

# رسائل الحالة (نجاح / تنبيه / خطأ)
msg_success() {
    echo -e "  ${C_GREEN}✔ $1${C_RESET}"
}

msg_error() {
    echo -e "  ${C_RED}✖ $1${C_RESET}"
}

msg_info() {
    echo -e "  ${C_CYAN}ℹ $1${C_RESET}"
}

# زر المتابعة
ui_pause() {
    echo ""
    read -p "  Press [Enter] key to continue..." _
}
