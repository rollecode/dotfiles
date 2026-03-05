#!/bin/bash
# Auto-update Discord before launching to avoid stuck splash screen
sudo pacman -Sy discord --noconfirm 2>/dev/null
exec discord --start-minimized
