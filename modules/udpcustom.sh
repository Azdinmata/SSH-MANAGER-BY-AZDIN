#!/bin/bash
export LC_ALL=C

systemctl stop udp-custom 2>/dev/null || true
pkill -9 -f udp-custom 2>/dev/null || true

mkdir -p /root/udp
mkdir -p /usr/local/bin

# تحميل النسخة المستقرة لملف التشغيل حسب معمارية السيرفر
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    wget -q -O /usr/local/bin/udp-custom "https://raw.githubusercontent.com/rull21/udp-custom/main/bin/udp-custom-linux-amd64" 2>/dev/null || \
    wget -q -O /usr/local/bin/udp-custom "https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main/bin/udp-custom" 2>/dev/null || true
fi

chmod +x /usr/local/bin/udp-custom

# إنشاء ملف التكوين الخاص بخدمة UDP Custom
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

# إعداد خدمة systemd للتشغيل التلقائي والثبات
cat << 'EOF' > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Server by Azdin
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
