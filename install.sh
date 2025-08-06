#!/bin/bash

set -e

# Ensure ~/bin exists
mkdir -p "$HOME/bin"

# Create the script to run Discord container
cat << 'EOF' > "$HOME/bin/discord"
#!/bin/bash
docker run -d --rm \
  --name discord-web \
  -e FIREFOX_URL="https://discord.com/app" \
  -p 5800:5800 \
  jlesage/firefox
xdg-open http://localhost:5800
EOF

chmod +x "$HOME/bin/discord"

# Create .desktop entry
mkdir -p "$HOME/.local/share/applications"
cat << EOF > "$HOME/.local/share/applications/discord.desktop"
[Desktop Entry]
Name=Discord (Isolated)
Comment=Run Discord in Docker-contained Firefox
Exec=$HOME/bin/discord
Icon=$HOME/containerized-discord/assets/discord.png
Terminal=false
Type=Application
Categories=Network;Chat;
EOF

# Refresh desktop database
update-desktop-database "$HOME/.local/share/applications" || true

echo "Discord container installed. Find it in your application launcher."
