#!/usr/bin/env bash
# ssh-password-bootstrap.sh — run a local script on a remote host (stdin free for passwords).
# Sourced by provision-macos-remote.sh and install-from-mac.sh (nas).

ssh_can_batch() {
  local target=$1
  ssh -o BatchMode=yes -o ConnectTimeout=8 -i "${HOME}/.ssh/id_ed25519" "$target" true 2>/dev/null
}

# Upload script: try scp; UGOS often blocks scp writes — fall back to base64 over ssh.
ssh_upload_script() {
  local target=$1 script=$2 remote_path=$3
  local -a ssh_key=(
    -o BatchMode=yes
    -o ConnectTimeout=12
    -i "${HOME}/.ssh/id_ed25519"
  )

  if scp "${ssh_key[@]}" "$script" "${target}:${remote_path}" 2>/dev/null; then
    return 0
  fi

  printf '→ scp blocked; uploading via base64 over SSH…\n'
  local b64
  b64=$(base64 <"$script" | tr -d '\n')
  ssh "${ssh_key[@]}" "$target" \
    "echo '${b64}' | base64 -d > '${remote_path}' && chmod +x '${remote_path}'"
}

# Password-only login (Mac bootstrap when no admin key yet).
ssh_password_bootstrap() {
  local bootstrap=$1 script=$2 remote_prefix=$3
  local remote_path="claude-bootstrap-$$.sh"
  local ssh_opts=(
    -F /dev/null
    -o ConnectTimeout=12
    -o PreferredAuthentications=password,keyboard-interactive
    -o PubkeyAuthentication=no
  )

  printf '→ Copying script to %s (admin password)…\n' "$bootstrap"
  scp "${ssh_opts[@]}" "$script" "${bootstrap}:${remote_path}"

  printf '→ Running on %s (admin password, then sudo password)…\n' "$bootstrap"
  ssh -tt "${ssh_opts[@]}" "$bootstrap" \
    "${remote_prefix} ${remote_path} && rm -f ${remote_path}"
}

# Key login to admin@host; only sudo password at prompt (UGOS / NAS path).
ssh_key_bootstrap() {
  local target=$1 script=$2 remote_prefix=$3
  local remote_path="claude-bootstrap-$$.sh"

  printf '→ Using SSH key as %s (sudo password only)…\n' "$target"
  ssh_upload_script "$target" "$script" "$remote_path"
  ssh -tt -o ConnectTimeout=12 -i "${HOME}/.ssh/id_ed25519" "$target" \
    "${remote_prefix} ~/${remote_path##*/} && rm -f ~/${remote_path##*/}"
}

# Pick key or password automatically.
ssh_smart_bootstrap() {
  local target=$1 script=$2 remote_prefix=$3
  if ssh_can_batch "$target"; then
    ssh_key_bootstrap "$target" "$script" "$remote_prefix"
  else
    ssh_password_bootstrap "$target" "$script" "$remote_prefix"
  fi
}
