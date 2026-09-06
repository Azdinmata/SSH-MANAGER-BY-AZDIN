#!/bin/bash
export LC_ALL=C

systemctl stop udp-custom 2>/dev/null || true
pkill -9 -f udp-custom 2>/dev/null || true

mkdir -p /root/udp
mkdir -p /usr/local/bin

# تنزيل نسخة مستقرة ومباشرة لـ udp-custom
rm -f /usr/local/bin/udp-custom
wget -q -O /usr/local/bin/udp-custom "https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main/bin/udp-custom" 2>/dev/null || \
curl -sL -o /usr/local/bin/udp-custom "https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main/bin/udp-custom" 2>/dev/null

# إذا لم يكن الملف مرفوعاً في مستودعك، نقوم بتحميله من بديل شغال ومباشر
if [ ! -s /usr/local/bin/udp-custom ]; then
    wget -q -O /usr/local/bin/udp-custom "https://github.com/PrivateTunnel/udp-custom/raw/main/bin/udp-custom-linux-amd64" 2>/dev/null || \
    curl -sL -o /usr/local/bin/udp-custom "https://github.com/PrivateTunnel/udp-custom/raw/main/bin/udp-custom-linux-amd64" 2>/dev/null
fi

chmod +x /usr/local/bin/udp-custom

# التأكد من حجم الملف قبل التشغيل
if [ ! -s /usr/local/bin/udp-custom ]; then
    echo "Error: udp-custom binary download failed!"
    exit 1
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
User=root
WorkingDirectory=/root/udp
ExecStart=/usr/local/bin/udp-custom server -c /root/udp/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom
