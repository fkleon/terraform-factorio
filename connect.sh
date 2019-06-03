#!/bin/sh
# Connect to the Factorio server via SSH.
set -e
SERVER_IP=$(cd instance/ && terraform output ip)

ssh -oStrictHostKeyChecking=no -i "~/.ssh/id_factorio" -l ubuntu ${SERVER_IP}
