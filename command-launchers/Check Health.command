#!/usr/bin/env bash
# Double-clickable launcher for tools/health.sh
cd "$(dirname "$0")/.." || exit 1
clear
bash tools/health.sh --infer
echo
read -r -p "Press Enter to close this window... " _
