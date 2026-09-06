#!/bin/bash
export LC_ALL=C
NS_DOMAIN=$(cat /etc/ssh-manager/nsdomain.conf 2>/dev/null || echo "ns.domain.com")

systemctl stop dnstt 2>/dev/null || true
pkill -9 -f dnstt-server 2>/dev/null || true

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    wget -q -O /usr/local/bin/dnstt-server "https://github.com/mhsanaei/3x-ui/raw/main/bin/dnstt-server-linux-amd64" 2>/dev/null || true
fi
chmod +x /usr/local/bin/dnstt-server 2>/dev/null || true

if [ -f /usr/local/bin/dnstt-server ]; then
    mkdir -p /etc/ssh-manager/dnstt
    if [ ! -f /etc/ssh-manager/dnstt/server.key ]; then
        /usr/local/bin/dnstt-server -gen-key -privkey-file /etc/ssh-manager/dnstt/server.key -pubkey-file /etc/ssh-manager/dnstt/server.pub 2>/dev/null || true
    fi

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
