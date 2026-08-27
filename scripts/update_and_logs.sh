#!/usr/bin/env bash
# Incremental prod update: git pull + cached `docker compose up --build` + logs.
# Enough for ordinary Dart/code edits. For new packages, Dockerfile, compose,
# or a stale image use `scripts/full_deploy.sh` instead.
set -euo pipefail

cd /opt/course-chatbot
git pull --ff-only
mkdir -p data

docker compose up -d --build

# Keep disk usage stable: drop old build cache and dangling images
# while preserving recently used cache for faster incremental builds.
docker builder prune -af --filter "until=168h"
docker image prune -f

docker logs --tail=200 course-chatbot
