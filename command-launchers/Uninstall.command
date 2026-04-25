#!/usr/bin/env bash
# Double-clickable launcher for uninstall.sh
cd "$(dirname "$0")/.." || exit 1
clear
printf "\033[1;33mYou-Sir Juan — Uninstaller\033[0m\n\n"
printf "This will remove the AI services (Ollama, Open WebUI, OpenClaw)\n"
printf "from this Mac. You'll be prompted before each destructive step.\n\n"
read -r -p "Continue? [y/N] " yn
if [[ ! "$yn" =~ ^[Yy]$ ]]; then
  printf "\nAborted.\n"
  read -r -p "Press Enter to close... " _
  exit 0
fi
echo
bash tools/uninstall.sh
echo
read -r -p "Press Enter to close this window... " _
