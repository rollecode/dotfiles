#!/bin/bash
# Ensure hyprpm plugins are built for the current Hyprland version
# Runs on Hyprland startup to handle post-update rebuilds

hyprpm update --no-shallow 2>&1 | logger -t hyprpm-ensure
hyprpm reload -n 2>&1 | logger -t hyprpm-ensure
