#!/bin/bash

CLIENT_NAME=$1

if [ -z "$CLIENT_NAME" ]; then
  echo "Usage: ./init-client-assistant.sh client-name"
  exit 1
fi

BASE_DIR="clients/$CLIENT_NAME"

mkdir -p "$BASE_DIR"
mkdir -p "$BASE_DIR/assistants"
mkdir -p "$BASE_DIR/documents"
mkdir -p "$BASE_DIR/memory"
mkdir -p "$BASE_DIR/policies"
mkdir -p "$BASE_DIR/logs"

cat > "$BASE_DIR/CLAUDE.md" << EOF
# $CLIENT_NAME Workspace Policy

## Privacy Rules
- Customer memory remains isolated.
- Family office data may never enter shared namespaces.
- Cloud APIs require explicit approval.

## Namespace Structure
- client:$CLIENT_NAME:*
EOF

cat > "$BASE_DIR/client-profile.md" << EOF
# Client Profile

## Workspace Name
$CLIENT_NAME

## Assistant Roles
- nanny
- coach
- household

## Privacy Tier
private
EOF

mkdir -p "$BASE_DIR/assistants/nanny"
mkdir -p "$BASE_DIR/assistants/coach"
mkdir -p "$BASE_DIR/assistants/household"

cat > "$BASE_DIR/assistants/nanny/assistant-profile.md" << EOF
# Nanny Assistant

## Role
Household continuity assistant.

## Responsibilities
- schedules
- routines
- reminders
- child continuity
EOF

echo "Workspace initialized at $BASE_DIR"
