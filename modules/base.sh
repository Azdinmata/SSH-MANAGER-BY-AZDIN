#!/bin/bash
export LC_ALL=C

# تعطيل الفايروول وتنظيف القواعد
which ufw >/dev/null 2>&1 && ufw disable 2>/dev/null || true
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# تثبيت الحزم الأساسية
apt-get update -y
apt-get install -y git curl wget unzip tar socat cron jq uuid-runtime net-tools iptables openssl cmake build-essential golang-go python3

# تعطيل احتكار بورت 53
if grep -q "DNSStubListener" /etc/systemd/resolved.conf; then
    sed -i 's/^#*DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
else
    echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
fi
systemctl restart systemd-resolved 2>/dev/null || true

# تفعيل BBR
grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1

# ضبط SSH لمنع الانقطاع
sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 20/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 5/' /etc/ssh/sshd_config
sed -i 's/^#*TCPKeepAlive.*/TCPKeepAlive yes/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

# مانع تعدد الجلسات (Max 2 Sessions)
cat << 'EOF' > /usr/local/bin/session-watchdog
#!/bin/bash
DB="/etc/ssh-manager/users.db"
[[ ! -f "$DB" ]] && exit 0
while IFS=: read -r user pass exp limit bw _; do
    [[ -z "$user" || "$user" =~ ^# ]] && continue
    limit=${limit:-2}
    online=$(ps -u "$user" -o comm= 2>/dev/null | grep -E '^sshd$' | wc -l)
    if [ "$online" -gt "$limit" ]; then
        pkill -u "$user" -o sshd
    fi
done < "$DB"
EOF
chmod +x /usr/local/bin/session-watchdog
(crontab -l 2>/dev/null | grep -v "session-watchdog"; echo "* * * * * /usr/local/bin/session-watchdog") | crontab -
