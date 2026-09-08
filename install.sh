#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

# Colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[38;5;48m"
C_YELLOW="\033[38;5;220m"
C_CYAN="\033[38;5;51m"
C_RED="\033[38;5;196m"

clear
echo -e "${C_CYAN}==========================================${C_RESET}"
echo -e "${C_BOLD}${C_YELLOW}    SSH-MANAGER-BY-AZDIN INSTALLER       ${C_RESET}"
echo -e "${C_CYAN}==========================================${C_RESET}"

# 1. Update and install base packages
echo -e "\n[*] Updating system repositories..."
apt-get update -y
apt-get install -y curl wget git unzip python3 iptables openssl jq net-tools

# 2. Setup directories
mkdir -p /etc/ssh-manager
mkdir -p /etc/ssh-manager/ui
mkdir -p /etc/ssh-manager/modules
touch /etc/ssh-manager/users.db

# 3. Ask or detect domain
read -p "Enter your Domain / Server Hostname (e.g. moha.freefrnet.space): " DOMAIN_INPUT
DOMAIN_INPUT=${DOMAIN_INPUT:-"127.0.0.1"}
echo "$DOMAIN_INPUT" > /etc/ssh-manager/domain.conf

# 4. Universal SSH & PAM Authentication Hardening
echo -e "\n[*] Hardening SSH & PAM settings..."
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf 2>/dev/null
rm -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf 2>/dev/null

cat << 'EOF' > /etc/ssh/sshd_config.d/00-override.conf
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PubkeyAuthentication yes
UsePAM yes
AuthenticationMethods password publickey,password keyboard-interactive
EOF

sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth 2>/dev/null || true

systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

# 5. SlowDNS (DNSTT) Installation & Service Setup
echo -e "\n[*] Setting up SlowDNS (DNSTT)..."
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  DNSTT_ARCH="amd64" ;;
  aarch64) DNSTT_ARCH="arm64" ;;
  armv7l)  DNSTT_ARCH="armv7" ;;
  *)       DNSTT_ARCH="amd64" ;;
esac

mkdir -p /etc/slowdns
curl -fsSL -o /usr/local/bin/dnstt-server "https://github.com/cbeuw/dnstt/releases/latest/download/dnstt-server-linux-${DNSTT_ARCH}" 2>/dev/null
chmod +x /usr/local/bin/dnstt-server

if [ -x /usr/local/bin/dnstt-server ] && [ ! -f /etc/slowdns/server.key ]; then
    /usr/local/bin/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub 2>/dev/null || true
fi

cat << EOF > /etc/systemd/system/dnstt.service
[Unit]
Description=SlowDNS (DNSTT) Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key ns.${DOMAIN_INPUT} 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dnstt 2>/dev/null || true
systemctl restart dnstt 2>/dev/null || true

# 6. Download UI Components & Menu
echo -e "\n[*] Fetching core scripts from GitHub..."
BASE_URL="https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main"

for comp in colors banner buttons cards; do
    curl -fsSL -o "/etc/ssh-manager/ui/$comp.sh" "$BASE_URL/ui/$comp.sh" 2>/dev/null
    chmod +x "/etc/ssh-manager/ui/$comp.sh" 2>/dev/null
done

curl -fsSL -o /usr/local/bin/menu "$BASE_URL/menu.sh"
chmod +x /usr/local/bin/menu

echo -e "\n${C_GREEN}[✔] Installation Finished! Type 'menu' to begin.${C_RESET}"
