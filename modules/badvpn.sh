#!/bin/bash
export LC_ALL=C

systemctl stop badvpn 2>/dev/null || true
pkill -9 -f badvpn-udpgw 2>/dev/null || true

cd /tmp
rm -rf badvpn
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
