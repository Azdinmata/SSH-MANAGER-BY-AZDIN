#!/bin/bash
export LC_ALL=C

systemctl stop udp-custom 2>/dev/null || true
pkill -9 -f udp-custom 2>/dev/null || true

mkdir -p /root/udp
mkdir -p /usr/local/bin

# تحميل الملف الثنائي لـ udp-custom برابط مباشر وموثوق
rm -f /usr/local/bin/udp-custom
wget -O /usr/local/bin/udp-custom "https://github.com/rull21/udp-custom/raw/main/bin/udp-custom-linux-amd64" 2>/dev/null || \
curl -L -o /usr/local/bin/udp-custom "https://github.com/rull21/udp-custom/raw/main/bin/udp-custom-linux-amd64" 2>/dev/null

chmod +x /usr/local/bin/udp-custom

# إنشاء ملف التكوين
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

# إعداد خدمة systemd
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
