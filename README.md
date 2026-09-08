# SSH-MANAGER-BY-AZDIN

---

### Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Azdinmata/SSH-MANAGER-BY-AZDIN/main/install.sh)```

---

### Authentication Fix (Not for all)

# 1. Clean out cloud-init overrides that force-disable password logins
```bash
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf 2>/dev/null
rm -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf 2>/dev/null
```

# 2. Force SSH daemon to accept passwords and keyboard-interactive via PAM
```bash
cat << 'EOF' > /etc/ssh/sshd_config.d/00-override.conf
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PubkeyAuthentication yes
UsePAM yes
AuthenticationMethods password publickey,password keyboard-interactive
EOF
```

# 3. Patch the root sshd_config fallback directly
```bash
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
```

# 4. Configure PAM common-auth to accept standard unix passwords
```bash
sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth 2>/dev/null || true
```

# 5. Fix Dropbear if installed
```bash
if [ -f /etc/default/dropbear ]; then
    sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
    sed -i 's/DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-p 109 -p 443"/' /etc/default/dropbear
fi
```

# 6. Apply and reload all daemon instances
```bash
sshd -t && (systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null)
systemctl restart dropbear 2>/dev/null || true
systemctl restart ws-dropbear 2>/dev/null || true
```
