#!/bin/bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

echo "Stopping all BaSyx-related infrastructure..."

# 1. Try Compose first
if [ -d "$ROOT/aas-test-backend" ]; then
  cd "$ROOT/aas-test-backend"
  docker compose down --remove-orphans || true
fi

# 2. Kill by Name (aas-ui and mongo)
docker stop aas-ui mongo 2>/dev/null || true
docker rm aas-ui mongo 2>/dev/null || true

# 3. Kill Mosquitto specifically by Image (The "Restarting" Fix)
MOSQUITTO_IDS=$(docker ps -a -q --filter ancestor=eclipse-mosquitto:2.0.15)
if [ -n "$MOSQUITTO_IDS" ]; then
    echo "Found Mosquitto containers. Forcing removal..."
    docker rm -f $MOSQUITTO_IDS
fi

# 4. Final Port Cleanup
PID=$(lsof -t -i:3000 || true)
[ -n "$PID" ] && kill -9 "$PID"

echo "Environment is now completely clean."