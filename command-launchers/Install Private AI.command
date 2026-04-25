#!/usr/bin/env bash
# Double-clickable launcher for the universal bootstrap
cd "$(dirname "$0")/.." || exit 1
clear
printf "\033[1mYou-Sir Juan — Private AI Installer\033[0m\n"
printf "(this Terminal window opened from Finder)\n\n"
bash bootstrap.sh
EXIT_CODE=$?
echo
if (( EXIT_CODE == 0 )); then
  printf "\033[0;32m✓ Installer finished successfully.\033[0m\n\n"
else
  printf "\033[0;31m✗ Installer exited with code %d.\033[0m See the output above.\n\n" "$EXIT_CODE"
fi
read -r -p "Press Enter to close this window... " _
