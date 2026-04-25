#!/usr/bin/env bash
# Double-clickable launcher for tools/backup.sh
cd "$(dirname "$0")/.." || exit 1
clear
printf "\033[1mYou-Sir Juan — Backup\033[0m\n\n"
bash tools/backup.sh
echo
read -r -p "Press Enter to close this window... " _
