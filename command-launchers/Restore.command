#!/usr/bin/env bash
# Double-clickable launcher for restore.sh — prompts for the backup file.
cd "$(dirname "$0")/.." || exit 1
clear
printf "\033[1mYou-Sir Juan — Restore\033[0m\n\n"
printf "Locate the backup file (.tgz) created by Backup.command.\n"
printf "Drag it into this Terminal window, OR paste its full path:\n\n"
read -r -p "    Backup file: " BACKUP
# Strip surrounding quotes/whitespace that drag-and-drop adds
BACKUP="${BACKUP#\'}"; BACKUP="${BACKUP%\'}"
BACKUP="${BACKUP#\"}"; BACKUP="${BACKUP%\"}"
BACKUP="${BACKUP%[[:space:]]}"
if [[ -z "$BACKUP" || ! -f "$BACKUP" ]]; then
  printf "\n\033[0;31mFile not found: %s\033[0m\n" "$BACKUP"
  read -r -p "Press Enter to close... " _
  exit 1
fi
echo
bash tools/restore.sh "$BACKUP"
echo
read -r -p "Press Enter to close this window... " _
