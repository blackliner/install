#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
DETECT_DIR="/etc/apt"
DETECT_SCRIPT="$DETECT_DIR/proxy-detect.sh"
APT_CONF_DIR="/etc/apt/apt.conf.d"
APT_CONF_FILE="$APT_CONF_DIR/30_detectproxy"

# === Create proxy detection script ===
echo "[INFO] Installing proxy detection script..."
tee "$DETECT_SCRIPT" >/dev/null <<'EOF'
#!/usr/bin/env bash
# Proxy auto-detection script for APT
# Expected output: "http://proxy:port" or "DIRECT"

TARGET_HOST="apt.proxy.local.berchtold.live"
TARGET_PORT=80

check_reachable() {
    # Prefer nc if available
    if command -v nc >/dev/null 2>&1; then
        nc -z -w2 "$TARGET_HOST" "$TARGET_PORT" >/dev/null 2>&1 && return 0
    fi
    # Fallback: ping
    if command -v ping >/dev/null 2>&1; then
        ping -c1 -W2 "$TARGET_HOST" >/dev/null 2>&1 && return 0
    fi
    return 1
}

if check_reachable; then
    echo "http://$TARGET_HOST:$TARGET_PORT"
else
    echo "DIRECT"
fi
EOF

chmod 755 "$DETECT_SCRIPT"

# === Configure APT to use proxy auto-detect ===
echo "[INFO] Configuring APT to use auto-detect script..."
tee "$APT_CONF_FILE" >/dev/null <<EOF
Acquire::http::Proxy-Auto-Detect "$DETECT_SCRIPT";
EOF

echo "[SUCCESS] Proxy auto-detect configuration installed."
