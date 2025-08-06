#!/bin/bash

set -e

# Install firejail if not present
if ! command -v firejail >/dev/null 2>&1; then
    echo "Installing firejail..."
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y firejail
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm firejail
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y firejail
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y firejail
    else
        echo "Warning: Could not install firejail automatically. Please install manually."
        echo "Using browser profile isolation instead."
    fi
fi

# Copy icon
ICON_SRC="$(pwd)/logo/jailed-discord.png"  
ICON_DEST="$HOME/.local/share/icons/jailed-discord.png"

mkdir -p "$(dirname "$ICON_DEST")"
cp -f "$ICON_SRC" "$ICON_DEST"

# Create isolated browser script
mkdir -p "$HOME/.local/bin"
cat << 'EOF' > "$HOME/.local/bin/discord"
#!/bin/bash

PROFILE_DIR="$HOME/.local/share/discord-browser"
mkdir -p "$PROFILE_DIR"

# Use firejail if available, otherwise use browser with isolated profile
if command -v firejail >/dev/null 2>&1; then
    firejail --private="$PROFILE_DIR" --netfilter \
             firefox --new-instance "https://discord.com/app"
elif command -v firefox >/dev/null 2>&1; then
    firefox --new-instance --profile "$PROFILE_DIR" "https://discord.com/app"
elif command -v chromium >/dev/null 2>&1; then
    chromium --user-data-dir="$PROFILE_DIR" --new-window "https://discord.com/app"
else
    xdg-open "https://discord.com/app"
fi
EOF

chmod +x "$HOME/.local/bin/discord"

# Create .desktop entry
mkdir -p "$HOME/.local/share/applications"
cat << EOF > "$HOME/.local/share/applications/discord.desktop"
[Desktop Entry]
Name=Discord (Isolated)
Comment=Run Discord in isolated browser profile
Exec=$HOME/.local/bin/discord
Icon=$ICON_DEST
Terminal=false
Type=Application
Categories=Network;Chat;
EOF

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "Discord launcher installed."
echo "Recommendation: Install firejail for better isolation"
echo "Add ~/.local/bin to PATH if needed"