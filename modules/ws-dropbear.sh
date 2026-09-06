#!/bin/bash
export LC_ALL=C

echo "[*] Installing & Configuring SSH-WebSocket Bridge (ws-dropbear)..."

# إيقاف أي خدمة سابقة لفك القفل
systemctl stop ws-dropbear 2>/dev/null || true
pkill -9 -f ws-dropbear 2>/dev/null || true

# كتابة سكربت البايثون الخاص بالجسر
cat << 'EOF' > /usr/local/bin/ws-dropbear
#!/usr/bin/env python3
import socket
import threading
import select

LISTEN_PORT = 10015
SSH_TARGET = ("127.0.0.1", 22)

def handle_client(client_sock):
    try:
        req = b""
        while b"\r\n\r\n" not in req:
            chunk = client_sock.recv(1024)
            if not chunk:
                client_sock.close()
                return
            req += chunk
        
        # الرد بموافقة مصافحة WebSocket (101 Switching Protocols)
        client_sock.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        
        target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target_sock.connect(SSH_TARGET)
        
        sockets = [client_sock, target_sock]
        while True:
            r, _, _ = select.select(sockets, [], [])
            if client_sock in r:
                data = client_sock.recv(4096)
                if not data:
                    break
                target_sock.sendall(data)
            if target_sock in r:
                data = target_sock.recv(4096)
                if not data:
                    break
                client_sock.sendall(data)
    except Exception:
        pass
    finally:
        client_sock.close()

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", LISTEN_PORT))
srv.listen(200)

while True:
    csock, _ = srv.accept()
    threading.Thread(target=handle_client, args=(csock,), daemon=True).start()
EOF

chmod +x /usr/local/bin/ws-dropbear

# إنشاء خدمة systemd
cat << 'EOF' > /etc/systemd/system/ws-dropbear.service
[Unit]
Description=SSH WebSocket Bridge
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/ws-dropbear
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-dropbear
systemctl restart ws-dropbear
