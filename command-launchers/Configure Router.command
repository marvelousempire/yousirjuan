#!/usr/bin/env bash
# Double-clickable launcher for glinet-router-setup.sh
cd "$(dirname "$0")/.." || exit 1
clear
printf "\033[1mGL.iNet Router Setup\033[0m\n"
printf "Make sure this Mac is connected to the router you want to configure.\n\n"
bash tools/glinet-router-setup.sh
echo
read -r -p "Press Enter to close this window... " _
