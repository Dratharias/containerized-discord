#!/bin/bash
# This script creates an isolated, sandboxed shortcut for the Discord web app.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Install Firejail (Sandboxing Tool) ---
# Check if firejail is installed. If not, try to install it using a common package manager.
if ! command -v firejail >/dev/null 2>&1; then
    echo "Firejail not found. Attempting to install..."
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y firejail
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm firejail
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y firejail
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y firejail
    else
        echo "Warning: Could not install firejail automatically. Please install it manually for sandboxing."
        echo "The script will proceed using browser-profile isolation instead."
    fi
fi

# --- Set up Paths and Icon ---
# Define the source and destination for the application icon.
# Note: This script assumes an icon exists at './logo/jailed-discord.png' relative to where the script is run.
ICON_SRC="$(pwd)/logo/jailed-discord.png"
ICON_DEST="$HOME/.local/share/icons/jailed-discord.png"

# Create the destination directory and copy the icon.
mkdir -p "$(dirname "$ICON_DEST")"
if [ -f "$ICON_SRC" ]; then
    cp -f "$ICON_SRC" "$ICON_DEST"
else
    echo "Warning: Icon file not found at '$ICON_SRC'. A default icon may be used."
    # As a fallback, we won't create an Icon entry if the source doesn't exist.
    ICON_DEST=""
fi


# --- Create the Launcher Script ---
# This script is what the .desktop shortcut will execute.
mkdir -p "$HOME/.local/bin"
cat << 'EOF' > "$HOME/.local/bin/discord"
#!/bin/bash

# Define a dedicated directory for the browser profile to keep it separate.
PROFILE_DIR="$HOME/.local/share/discord-browser"
mkdir -p "$PROFILE_DIR"

# The 'exec' command replaces the shell script process with the browser process.
# This is crucial for .desktop files to correctly track the application window.
# Without 'exec', the script would finish and the DE would think the app closed.

if command -v firejail >/dev/null 2>&1; then
    # Launch with Firejail for maximum security.
    exec firejail --private="$PROFILE_DIR" --x11 \
         firefox --new-instance "https://discord.com/app"
elif command -v firefox >/dev/null 2>&1; then
    # Fallback to Firefox with a separate profile if Firejail isn't available.
    exec firefox --new-instance --profile "$PROFILE_DIR" "https://discord.com/app"
elif command -v chromium >/dev/null 2>&1; then
    # Fallback to Chromium if Firefox isn't available.
    exec chromium --user-data-dir="$PROFILE_DIR" --new-window "https://discord.com/app"
else
    # Final fallback to the system's default browser handler.
    exec xdg-open "https://discord.com/app"
fi
EOF

# Make the launcher script executable.
chmod +x "$HOME/.local/bin/discord"

# --- Create the .desktop Application Shortcut ---
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

# --- Finalize ---
# Update the system's application database to make the new shortcut visible.
echo "Updating application database..."
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

# Add the local bin directory to PATH for the current session if it's not there.
# This is mainly for convenience if you want to run 'discord' from the terminal.
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "Installation complete!"
echo "You should now find 'Discord (Web)' in your application menu."
echo "Note: You may need to log out and log back in for the shortcut to appear."