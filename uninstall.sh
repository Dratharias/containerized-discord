#!/bin/bash
set -e

echo "Uninstalling Discord isolated launcher..."

# Remove the isolated browser script
if [ -f "$HOME/.local/bin/discord" ]; then
    rm "$HOME/.local/bin/discord"
    echo "Removed $HOME/.local/bin/discord"
else
    echo "No launcher script found at $HOME/.local/bin/discord"
fi

# Remove the .desktop entry
if [ -f "$HOME/.local/share/applications/discord.desktop" ]; then
    rm "$HOME/.local/share/applications/discord.desktop"
    echo "Removed $HOME/.local/share/applications/discord.desktop"
else
    echo "No desktop entry found at $HOME/.local/share/applications/discord.desktop"
fi

# Remove the icon file
if [ -f "$HOME/.local/share/icons/jailed-discord.png" ]; then
    rm "$HOME/.local/share/icons/jailed-discord.png"
    echo "Removed $HOME/.local/share/icons/jailed-discord.png"
else
    echo "No icon found at $HOME/.local/share/icons/jailed-discord.png"
fi

echo "Uninstallation complete."
