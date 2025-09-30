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
        timeout 0.1 nc -z "$TARGET_HOST" "$TARGET_PORT" >/dev/null 2>&1 && return 0
    # Fallback: ping
    elif command -v ping >/dev/null 2>&1; then
        timeout 0.1 ping -c1 "$TARGET_HOST" >/dev/null 2>&1 && return 0
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

# === Check for conflicting proxy settings ===
for file in "$APT_CONF_DIR"/*; do
    # Skip the file we just created
    [[ "$file" == "$APT_CONF_FILE" ]] && continue
    # Skip backup files
    [[ "$file" == *.bak ]] && continue

    if grep -Eq '^\s*Acquire::http::Proxy\s' "$file"; then
        echo "======================================================"
        echo "WARNING: File '$file' contains Acquire::http::Proxy settings."
        echo "------------------------------------------------------"
        cat "$file"
        echo "------------------------------------------------------"
        echo "Suggestion: move this file to a backup location to avoid conflicts, e.g.:"
        echo "  sudo mv '$file' '${file}.bak'"
        echo "======================================================"
        echo
    fi
done

echo "[SUCCESS] Proxy auto-detect configuration installed."
