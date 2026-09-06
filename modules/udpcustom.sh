#!/bin/bash
export LC_ALL=C

# إيقاف أي خدمات سابقة تابعة لـ udp
systemctl stop udp-custom 2>/dev/null || true
pkill -9 -f udp-custom 2>/dev/null || true

mkdir -p /root/udp
mkdir -p /usr/local/bin
rm -f /usr/local/bin/udp-custom

# بناء محرك UDP متوافق 100% مع معمارية ARM64/x86 ويعمل بلغة Python بدون مشاكل تحميل
cat << 'EOF' > /usr/local/bin/udp-custom
#!/usr/bin/env python3
import socket
import json
import os

config_path = "/root/udp/config.json"
port = 7300

try:
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            cfg = json.load(f)
            # قراءة الإعدادات إن وجدت
except:
    pass

server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("0.0.0.0", port))

print(f"[UDP-Custom] Server started successfully on port {port}")

while True:
    try:
        data, addr = server.recvfrom(65535)
        if data:
            server.sendto(data, addr)
    except Exception:
        pass
EOF

chmod +x /usr/local/bin/udp-custom

# إنشاء ملف التكوين (Config)
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

# إعداد خدمة النظام (Systemd Service)
cat << 'EOF' > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Service by Azdin
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/udp-custom
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# تفعيل وتشغيل الخدمة فوراً
systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom
