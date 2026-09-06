#!/bin/bash
export LC_ALL=C
NS_DOMAIN=$(cat /etc/ssh-manager/nsdomain.conf)

systemctl stop dnstt 2>/dev/null || true
pkill -9 -f dnstt-server 2>/dev/null || true

rm -rf /tmp/dnstt
git clone https://www.bamsoftware.com/git/dnstt.git /tmp/dnstt 2>/dev/null || true
if [ -d /tmp/dnstt/dnstt-server ]; then
    cd /tmp/dnstt/dnstt-server
    go build
    pkill -9 -f dnstt-server 2>/dev/null || true
    cp -f dnstt-server /usr/local/bin/dnstt-server
    chmod +x /usr/local/bin/dnstt-server
    cd /root && rm -rf /tmp/dnstt
fi

if [ -f /usr/local/bin/dnstt-server ]; then
    mkdir -p /etc/ssh-manager/dnstt
    /usr/local/bin/dnstt-server -gen-key -privkey-file /etc/ssh-manager/dnstt/server.key -pubkey-file /etc/ssh-manager/dnstt/server.pub 2>/dev/null || true

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
