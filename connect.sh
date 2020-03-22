#!/bin/bash
# Connect to the Factorio server via SSH.
set -e
SERVER_IP=$(cd instance/ && terraform output ip)
SSH_PRIVATE_KEY=$(cd instance/ && terraform output ssh_private_key)
SSH_PRIVATE_KEY_FILE=./id_factorio

if [ ${SERVER_IP:-0} == "0" ]; then
  echo "Cannot access required terraform state." >&2
  exit 1
fi

if [ -f "$SSH_PRIVATE_KEY_FILE" ]; then
  read -p "This will overwrite the existing private key at $SSH_PRIVATE_KEY_FILE, are you sure [y/n]?" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "$SSH_PRIVATE_KEY" > "$SSH_PRIVATE_KEY_FILE"
    chmod 0600 "$SSH_PRIVATE_KEY_FILE"
  else
    exit 1
  fi
fi

ssh -oStrictHostKeyChecking=accept-new -i "$SSH_PRIVATE_KEY_FILE" -l ubuntu ${SERVER_IP}
