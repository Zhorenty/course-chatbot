#!/usr/bin/env bash
set -euo pipefail

cd /opt/course-chatbot
docker compose restart
docker compose ps
