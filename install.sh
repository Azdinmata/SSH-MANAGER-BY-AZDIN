#!/bin/bash
export LC_ALL=C
clear

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

REPO_URL="https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main"

echo "========================================================"
echo "      SSH-MANAGER [By-AZDIN] COMPLETE INSTALLER         "
echo "========================================================"
echo ""
read -p "Enter Domain pointing to this VPS: " USER_DOMAIN
if [ -z "$USER_DOMAIN" ]; then
    echo "Domain cannot be empty."
    exit 1
fi

read -p "Enter Nameserver Domain for DNSTT (e.g. ns.domain.com): " NS_DOMAIN
NS_DOMAIN=${NS_DOMAIN:-"ns.$USER_DOMAIN"}

# تخصيص Swap 1GB لضمان عدم انهيار الجلسة بسبب نقص الرام OOM
if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024 2>/dev/null
    chmod 600 /swapfile
    mkswap /swapfile 2>/dev/null
    swapon /swapfile 2>/dev/null
fi

mkdir -p /etc/ssh-manager/ui
mkdir -p /etc/ssh-manager/dnstt
echo "$USER_DOMAIN" > /etc/ssh-manager/domain.conf
echo "$NS_DOMAIN" > /etc/ssh-manager/nsdomain.conf
touch /etc/ssh-manager/users.db

echo "[1/7] Base System & Optimizations..."
bash <(curl -fsSL "$REPO_URL/modules/base.sh")

echo "[2/7] WS-Dropbear Bridge..."
bash <(curl -fsSL "$REPO_URL/modules/ws-dropbear.sh")

echo "[3/7] SSL & Nginx Proxy..."
bash <(curl -fsSL "$REPO_URL/modules/ssl.sh")

echo "[4/7] V2Ray Multi-Protocol Core..."
bash <(curl -fsSL "$REPO_URL/modules/v2ray.sh")

echo "[5/7] BadVPN Gateway..."
bash <(curl -fsSL "$REPO_URL/modules/badvpn.sh")

echo "[6/7] UDP Custom Service..."
bash <(curl -fsSL "$REPO_URL/modules/udpcustom.sh")

echo "[7/7] SlowDNS (DNSTT)..."
bash <(curl -fsSL "$REPO_URL/modules/dnstt.sh")

echo "[*] Fetching UI Themes..."
for comp in colors banner buttons cards; do
    curl -fsSL -o "/etc/ssh-manager/ui/$comp.sh" "$REPO_URL/ui/$comp.sh" 2>/dev/null || true
    chmod +x "/etc/ssh-manager/ui/$comp.sh" 2>/dev/null || true
done

echo "[*] Installing Management Menu..."
curl -fsSL -o /usr/local/bin/ssh-manager "$REPO_URL/menu.sh"
chmod +x /usr/local/bin/ssh-manager
ln -sf /usr/local/bin/ssh-manager /usr/local/bin/menu
ln -sf /usr/local/bin/ssh-manager /bin/menu

echo "========================================================"
echo " INSTALLATION COMPLETED! Starting Dashboard...          "
echo "========================================================"
sleep 1
/usr/local/bin/menu
