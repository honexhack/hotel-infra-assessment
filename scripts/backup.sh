#!/usr/bin/env bash
set -euo pipefail

CONTAINER="hotel-db"
DB_USER="${POSTGRES_USER:-hotel}"
DB_NAME="${POSTGRES_DB:-hotel}"
BACKUP_DIR="./backups"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"

echo "Taking backup of db '$DB_NAME'..."
docker exec "$CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" --no-owner > "$BACKUP_FILE"

echo "Backup saved to $BACKUP_FILE"