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

mkdir -p /etc/ssh-manager
echo "$USER_DOMAIN" > /etc/ssh-manager/domain.conf
echo "$NS_DOMAIN" > /etc/ssh-manager/nsdomain.conf
touch /etc/ssh-manager/users.db

echo "[1/7] Setting up System Base & Firewall..."
bash <(curl -fsSL "$REPO_URL/modules/base.sh")

echo "[2/7] Setting up SSH WebSocket Bridge (ws-dropbear)..."
bash <(curl -fsSL "$REPO_URL/modules/ws-dropbear.sh")

echo "[3/7] Configuring SSL & Nginx..."
bash <(curl -fsSL "$REPO_URL/modules/ssl.sh")

echo "[4/7] Setting up V2Ray Engine..."
bash <(curl -fsSL "$REPO_URL/modules/v2ray.sh")

echo "[5/7] Building BadVPN Gateway..."
bash <(curl -fsSL "$REPO_URL/modules/badvpn.sh")

echo "[6/7] Setting up UDP Custom..."
bash <(curl -fsSL "$REPO_URL/modules/udpcustom.sh")

echo "[7/7] Setting up SlowDNS (DNSTT)..."
bash <(curl -fsSL "$REPO_URL/modules/dnstt.sh")

echo "[*] Downloading UI Theme Modules..."
mkdir -p /etc/ssh-manager/ui
for comp in colors banner buttons cards; do
    curl -fsSL -o "/etc/ssh-manager/ui/$comp.sh" "$REPO_URL/ui/$comp.sh"
    chmod +x "/etc/ssh-manager/ui/$comp.sh"
done

echo "[*] Installing Management Menu..."
curl -fsSL -o /usr/local/bin/ssh-manager "$REPO_URL/menu.sh"
chmod +x /usr/local/bin/ssh-manager
ln -sf /usr/local/bin/ssh-manager /usr/local/bin/menu
ln -sf /usr/local/bin/ssh-manager /bin/menu

echo "========================================================"
echo " INSTALLATION COMPLETED! Type 'menu' to begin.          "
echo "========================================================"#!/bin/bash
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

mkdir -p /etc/ssh-manager
echo "$USER_DOMAIN" > /etc/ssh-manager/domain.conf
echo "$NS_DOMAIN" > /etc/ssh-manager/nsdomain.conf
touch /etc/ssh-manager/users.db

echo "[1/7] Setting up System Base & Firewall..."
bash <(curl -fsSL "$REPO_URL/modules/base.sh")

echo "[2/7] Configuring SSL & Nginx..."
bash <(curl -fsSL "$REPO_URL/modules/ssl.sh")

echo "[3/7] Setting up SSH WebSocket Bridge..."
bash <(curl -fsSL "$REPO_URL/modules/ssh-ws.sh")

echo "[4/7] Setting up V2Ray Engine..."
bash <(curl -fsSL "$REPO_URL/modules/v2ray.sh")

echo "[5/7] Building BadVPN Gateway..."
bash <(curl -fsSL "$REPO_URL/modules/badvpn.sh")

echo "[6/7] Setting up UDP Custom..."
bash <(curl -fsSL "$REPO_URL/modules/udpcustom.sh")

echo "[7/7] Setting up SlowDNS (DNSTT)..."
bash <(curl -fsSL "$REPO_URL/modules/dnstt.sh")

echo "[*] Downloading Management Menu..."
curl -fsSL -o /usr/local/bin/ssh-manager "$REPO_URL/menu.sh"
chmod +x /usr/local/bin/ssh-manager
ln -sf /usr/local/bin/ssh-manager /usr/local/bin/menu
ln -sf /usr/local/bin/ssh-manager /bin/menu

echo "========================================================"
echo " INSTALLATION COMPLETED! Type 'menu' to begin.          "
echo "========================================================"
