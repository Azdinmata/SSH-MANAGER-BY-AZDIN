#!/bin/bash
export LC_ALL=C
clear

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

echo "========================================================"
echo "      SSH-MANAGER [By-AZDIN] COMPLETE INSTALLER         "
echo "========================================================"
echo ""
read -p "Enter GitHub Username (where menu.sh is hosted): " GH_USER
read -p "Enter GitHub Repo Name: " GH_REPO
read -p "Enter Domain pointing to this VPS: " USER_DOMAIN
if [ -z "$USER_DOMAIN" ] || [ -z "$GH_USER" ] || [ -z "$GH_REPO" ]; then
    echo "Inputs cannot be empty."
    exit 1
fi

read -p "Enter Nameserver Domain for DNSTT (e.g. ns.domain.com): " NS_DOMAIN
NS_DOMAIN=${NS_DOMAIN:-"ns.$USER_DOMAIN"}

mkdir -p /etc/ssh-manager/ssl
mkdir -p /etc/ssh-manager/dnstt
echo "$USER_DOMAIN" > /etc/ssh-manager/domain.conf
echo "$NS_DOMAIN" > /etc/ssh-manager/nsdomain.conf
touch /etc/ssh-manager/users.db

echo "[1/8] Opening Firewall and Clearing Ports..."
which ufw >/dev/null 2>&1 && ufw disable 2>/dev/null || true
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

echo "[2/8] Updating packages & preparing Port 53..."
apt-get update -y
apt-get install -y git curl wget unzip tar socat cron jq uuid-runtime net-tools iptables openssl cmake build-essential golang-go nginx certbot python3-certbot-nginx

if grep -q "DNSStubListener" /etc/systemd/resolved.conf; then
    sed -i 's/^#*DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
else
    echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
fi
systemctl restart systemd-resolved 2>/dev/null || true

echo "[3/8] Freeing Ports 80 & 443 and Issuing SSL Certificate..."
systemctl stop nginx apache2 2>/dev/null || true
fuser -k 80/tcp 443/tcp 2>/dev/null || true

certbot certonly --standalone --preferred-challenges http -d "$USER_DOMAIN" --register-unsafely-without-email --agree-tos --non-interactive

echo "[4/8] Installing V2Ray Core (VMess, Trojan, VLESS)..."
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) 2>/dev/null || true

cat << 'EOF' > /usr/local/etc/v2ray/config.json
{
  "log": { "loglevel": "none" },
  "inbounds": [
    {
      "port": 10000,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/v2ray" } }
    },
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } }
    },
    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
EOF
systemctl enable v2ray
systemctl restart v2ray

echo "[5/8] Configuring Nginx Reverse Proxy..."
cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    listen [::]:80;
    server_name $USER_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $USER_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$USER_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$USER_DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:22;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    location /v2ray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
EOF
systemctl enable nginx
systemctl restart nginx

echo "[6/8] Building & Starting BadVPN, UDP Custom & DNSTT..."
# BadVPN
cd /tmp
git clone https://github.com/ambrop72/badvpn.git
cd badvpn
cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
cd /root && rm -rf /tmp/badvpn

cat << 'EOF' > /etc/systemd/system/badvpn.service
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable badvpn
systemctl restart badvpn

# UDP Custom
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    wget -q -O /usr/local/bin/udp-custom "https://raw.githubusercontent.com/rull21/udp-custom/main/bin/udp-custom-linux-amd64" 2>/dev/null || true
else
    wget -q -O /usr/local/bin/udp-custom "https://raw.githubusercontent.com/rull21/udp-custom/main/bin/udp-custom-linux-arm64" 2>/dev/null || true
fi
chmod +x /usr/local/bin/udp-custom 2>/dev/null || true

mkdir -p /root/udp
cat << 'EOF' > /root/udp/config.json
{
  "listen": ":1-65535",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
EOF

cat << 'EOF' > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
ExecStart=/usr/local/bin/udp-custom server -c /root/udp/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable udp-custom 2>/dev/null || true
systemctl restart udp-custom 2>/dev/null || true

# DNSTT
git clone https://www.bamsoftware.com/git/dnstt.git /tmp/dnstt 2>/dev/null || true
if [ -d /tmp/dnstt/dnstt-server ]; then
    cd /tmp/dnstt/dnstt-server
    go build
    cp dnstt-server /usr/local/bin/dnstt-server
    chmod +x /usr/local/bin/dnstt-server
    cd /root && rm -rf /tmp/dnstt
fi

if [ -f /usr/local/bin/dnstt-server ]; then
    /usr/local/bin/dnstt-server -gen-key -privkey-file /etc/ssh-manager/dnstt/server.key -pubkey-file /etc/ssh-manager/dnstt/server.pub
    cat << EOF > /etc/systemd/system/dnstt.service
[Unit]
Description=DNSTT SlowDNS Server
After=network.target

[Service]
ExecStart=/usr/local/bin/dnstt-server -udp :53 -privkey-file /etc/ssh-manager/dnstt/server.key $NS_DOMAIN 127.0.0.1:22
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable dnstt
    systemctl restart dnstt
fi

echo "[7/8] Applying Anti-Drop, BBR Acceleration & 2-Sessions Limiter..."
grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1

sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 20/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 5/' /etc/ssh/sshd_config
sed -i 's/^#*TCPKeepAlive.*/TCPKeepAlive yes/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

cat << 'EOF' > /usr/local/bin/session-watchdog
#!/bin/bash
DB="/etc/ssh-manager/users.db"
[[ ! -f "$DB" ]] && exit 0

while IFS=: read -r user pass exp limit bw _; do
    [[ -z "$user" || "$user" =~ ^# ]] && continue
    limit=${limit:-2}
    online=$(ps -u "$user" -o comm= 2>/dev/null | grep -E '^sshd$' | wc -l)
    if [ "$online" -gt "$limit" ]; then
        pkill -u "$user" -o sshd
    fi
done < "$DB"
EOF
chmod +x /usr/local/bin/session-watchdog
(crontab -l 2>/dev/null | grep -v "session-watchdog"; echo "* * * * * /usr/local/bin/session-watchdog") | crontab -

echo "[8/8] Fetching Dashboard Menu from GitHub..."
curl -fsSL -o /usr/local/bin/ssh-manager "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/menu.sh"
chmod +x /usr/local/bin/ssh-manager
ln -sf /usr/local/bin/ssh-manager /usr/local/bin/menu
ln -sf /usr/local/bin/ssh-manager /bin/menu

echo "========================================================"
echo " INSTALLATION FINISHED! Type 'menu' to access dashboard "
echo "========================================================"
