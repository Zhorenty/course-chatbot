#!/usr/bin/env bash
# Pull latest code and rebuild the bot container.
# On the VPS after a git push:
#   ssh course-bot 'cd /opt/course-chatbot && ./scripts/deploy.sh'
# Rebuild without Docker cache:
#   NO_CACHE=1 ./scripts/deploy.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f compose.yaml ]]; then
  echo "error: compose.yaml not found in $ROOT" >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "error: .env is missing. Copy .env.example and fill secrets first." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is not installed" >&2
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
BEFORE="$(git rev-parse --short HEAD)"

echo "==> fetching $BRANCH in $ROOT"
git fetch origin
git pull --ff-only origin "$BRANCH"

AFTER="$(git rev-parse --short HEAD)"
if [[ "$BEFORE" == "$AFTER" ]]; then
  echo "==> already at $AFTER, rebuilding anyway"
else
  echo "==> $BEFORE → $AFTER"
fi

if [[ "${NO_CACHE:-}" == "1" ]]; then
  echo "==> docker compose build --no-cache --pull"
  docker compose build --no-cache --pull
  docker compose up -d --force-recreate --remove-orphans
else
  echo "==> docker compose up -d --build"
  docker compose up -d --build --remove-orphans
fi

echo "==> waiting for http://127.0.0.1:8080/health"
deadline=$((SECONDS + 90))
until curl -fsS http://127.0.0.1:8080/health >/dev/null 2>&1; do
  if (( SECONDS >= deadline )); then
    echo "error: container did not become healthy" >&2
    docker compose ps
    docker compose logs --tail=80
    exit 1
  fi
  sleep 2
done

echo "==> healthy"
docker compose ps
echo "follow logs: docker compose logs -f --tail=80"
