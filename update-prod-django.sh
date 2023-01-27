#!/bin/bash
echo "[START]"
echo "---stopping django---"
docker compose stop django
echo "---removing containers---"
docker compose rm -f
echo "---removing stale volumes---"
docker volume prune -f
echo "---rebuilding django---"
docker compose build django
echo "---restarting django---"
docker compose -f docker-compose.yml up -d --no-deps django
echo "[END]"
