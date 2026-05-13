#!/bin/bash
# Reload hyprpm plugins on Hyprland startup.
#
# We deliberately do NOT run `hyprpm update` here. The previous version of
# this script ran `hyprpm update --no-shallow` every login, which rebuilt
# every enabled plugin from upstream and clobbered any locally-patched .so
# files (e.g. our hyprbars m_bCancelledDown leak fix, hymission z-order
# patch). Run `hyprpm update` manually when you actually want to pull
# upstream changes, then re-apply local patches with the deploy scripts in
# this directory.

hyprpm reload -n 2>&1 | logger -t hyprpm-ensure
