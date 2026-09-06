#!/bin/bash
export LC_ALL=C

# 1. إيقاف الخدمة الحالية وتنظيف المجلدات
systemctl stop udp-custom 2>/dev/null || true
pkill -9 -f udp-custom 2>/dev/null || true

mkdir -p /root/udp
mkdir -p /usr/local/bin

# 2. تحميل الملف الثنائي لـ udp-custom مع التحقق التام من نجاح التحميل
rm -f /usr/local/bin/udp-custom
wget -q -O /usr/local/bin/udp-custom "https://github.com/PrivateTunnel/udp-custom/raw/main/bin/udp-custom-linux-amd64" 2>/dev/null || \
curl -sL -o /usr/local/bin/udp-custom "https://github.com/PrivateTunnel/udp-custom/raw/main/bin/udp-custom-linux-amd64" 2>/dev/null

# التأكد أن الملف غير فارغ وله صلاحيات التنفيذ الإجبارية
chmod +x /usr/local/bin/udp-custom
if [ ! -s /usr/local/bin/udp-custom ]; then
    echo "Error: Failed to download udp-custom binary."
    exit 1
fi

# 3. إنشاء ملف التكوين بصيغة سليمة
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

# 4. تصحيح إعدادات systemd بالمسارات المطلقة المباشرة لمنع خطأ 203/EXEC
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

# 5. إعادة تحميل النظام وتشغيل الخدمة
systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom
