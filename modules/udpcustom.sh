#!/bin/bash
export LC_ALL=C

systemctl stop udp-custom 2>/dev/null || true
pkill -9 -f udp-custom 2>/dev/null || true

mkdir -p /root/udp
mkdir -p /usr/local/bin
rm -f /usr/local/bin/udp-custom

# فحص المعمارية وجلب الملف الثنائي الصحيح لـ ARM64 مباشرة بدون أخطاء
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    curl -L -o /usr/local/bin/udp-custom "https://raw.githubusercontent.com/PrivateTunnel/udp-custom/main/bin/udp-custom-linux-arm64" 2>/dev/null || \
    wget -O /usr/local/bin/udp-custom "https://raw.githubusercontent.com/PrivateTunnel/udp-custom/main/bin/udp-custom-linux-arm64" 2>/dev/null
else
    curl -L -o /usr/local/bin/udp-custom "https://raw.githubusercontent.com/PrivateTunnel/udp-custom/main/bin/udp-custom-linux-amd64" 2>/dev/null || \
    wget -O /usr/local/bin/udp-custom "https://raw.githubusercontent.com/PrivateTunnel/udp-custom/main/bin/udp-custom-linux-amd64" 2>/dev/null
fi

chmod +x /usr/local/bin/udp-custom

# التحقق من أن الملف ليس نصاً والتأكد من توافقه
if file /usr/local/bin/udp-custom | grep -q "text"; then
    echo "Trying fallback binary..."
    rm -f /usr/local/bin/udp-custom
    curl -L -o /usr/local/bin/udp-custom "https://github.com/rull21/udp-custom/raw/main/bin/udp-custom-linux-arm64" 2>/dev/null
    chmod +x /usr/local/bin/udp-custom
fi

cat << 'EOF' > /root/udp/config.json
{
  "listen": ":7300",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
EOF

cat << 'EOF' > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Service by Azdin
After=network.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/udp-custom server -c /root/udp/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom
