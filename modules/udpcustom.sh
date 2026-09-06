#!/bin/bash
export LC_ALL=C

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
