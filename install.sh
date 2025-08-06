#!/bin/bash
# This script creates an isolated, sandboxed shortcut for the Discord web app using Bubblewrap.

set -e

# --- Check for Bubblewrap ---
if ! command -v bwrap >/dev/null 2>&1; then
    echo "Bubblewrap not found. Attempting to install..."
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y bubblewrap
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm bubblewrap
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y bubblewrap
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y bubblewrap
    else
        echo "Warning: Could not install bubblewrap automatically. Please install it manually for sandboxing."
        echo "The script will proceed using browser-profile isolation instead."
    fi
fi

# --- Set up Icon ---
ICON_SRC="$(pwd)/logo/jailed-discord.png"
ICON_DEST="$HOME/.local/share/icons/jailed-discord.png"

mkdir -p "$(dirname "$ICON_DEST")"
if [ -f "$ICON_SRC" ]; then
    cp -f "$ICON_SRC" "$ICON_DEST"
else
    echo "Warning: Icon file not found at '$ICON_SRC'. A default icon may be used."
    ICON_DEST=""
fi

# --- Create launcher script ---
mkdir -p "$HOME/.local/bin"
cat << 'EOF' > "$HOME/.local/bin/discord"
#!/bin/bash

BASE_PROFILE_DIR="$HOME/.local/share/discord-browser"
mkdir -p "$BASE_PROFILE_DIR"

# Create fresh temp profile directory per launch
TMP_PROFILE_DIR=$(mktemp -d "$BASE_PROFILE_DIR/tmp-discord-sandbox")

# Create Firefox profile if not already present
if [ ! -f "$TMP_PROFILE_DIR/profile.ini" ]; then
    firefox --no-remote -CreateProfile "sandbox $TMP_PROFILE_DIR"
fi

function can_use_bwrap_userns() {
    bwrap --unshare-user --ro-bind /usr /usr true >/dev/null 2>&1
}

if command -v bwrap >/dev/null 2>&1 && can_use_bwrap_userns; then
    FIREFOX_CMD="firefox"
    if [[ "$(readlink -f "$(which firefox)")" == *"/snap/"* ]]; then
        if [ -f "/usr/bin/firefox" ]; then
            FIREFOX_CMD="/usr/bin/firefox"
        fi
    fi

    exec bwrap \
        --dev-bind /dev /dev \
        --proc /proc \
        --tmpfs /tmp \
        --bind "$TMP_PROFILE_DIR" "$TMP_PROFILE_DIR" \
        --setenv HOME "$HOME" \
        --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR" \
        --setenv DISPLAY "$DISPLAY" \
        --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
        --setenv PULSE_SERVER "$PULSE_SERVER" \
        --setenv XDG_DATA_HOME "$XDG_DATA_HOME" \
        --ro-bind /usr /usr \
        --ro-bind /lib /lib \
        --ro-bind /lib64 /lib64 \
        --ro-bind /bin /bin \
        --ro-bind /etc /etc \
        --ro-bind /tmp /tmp \
        "$FIREFOX_CMD" --no-remote --new-instance --profile "$TMP_PROFILE_DIR" "https://discord.com/app"

else
    echo "Warning: Bubblewrap user namespaces unavailable or permission denied."
    echo "Launching without sandbox. Consider enabling user namespaces:"
    echo "  sudo sysctl kernel.unprivileged_userns_clone=1"
    echo "  Ensure /etc/subuid and /etc/subgid are properly configured."
    if command -v firefox >/dev/null 2>&1; then
        TMP_PROFILE_DIR=$(mktemp -d "$BASE_PROFILE_DIR/tmp-discord-sandbox")
        exec firefox --no-remote --new-instance --profile "$TMP_PROFILE_DIR" "https://discord.com/app"
    elif command -v chromium >/dev/null 2>&1; then
        exec chromium --user-data-dir="$BASE_PROFILE_DIR" --new-window "https://discord.com/app"
    else
        exec xdg-open "https://discord.com/app"
    fi
fi

EOF

chmod +x "$HOME/.local/bin/discord"

# --- Create the .desktop shortcut ---
mkdir -p "$HOME/.local/share/applications"
cat << EOF > "$HOME/.local/share/applications/discord.desktop"
[Desktop Entry]
Name=Discord (Web)
Comment=Run Discord in an isolated browser sandbox
Exec=$HOME/.local/bin/discord
Icon=$ICON_DEST
Terminal=false
Type=Application
Categories=Network;Chat;
EOF

echo "Updating application database..."
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

# Add local bin to PATH in current session if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "Installation complete!"
echo "You should now find 'Discord (Web)' in your application menu."
echo "You may need to log out and back in for changes to take effect."
