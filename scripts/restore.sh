#!/usr/bin/env bash
set -euo pipefail

CONTAINER="hotel-db"
DB_USER="${POSTGRES_USER:-hotel}"
SOURCE_DB="${POSTGRES_DB:-hotel}"
RESTORE_DB="hotel_restore"


if [ $# -ge 1 ]; then
  BACKUP_FILE="$1"
else
  BACKUP_FILE=$(ls -t ./backups/*.sql 2>/dev/null | head -n 1 || true)
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
  echo "No backup file found. Run ./scripts/backup.sh first."
  exit 1
fi

echo "Restoring $BACKUP_FILE into fresh database '$RESTORE_DB'..."

docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $RESTORE_DB;"
docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $RESTORE_DB;"
docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$RESTORE_DB" -v ON_ERROR_STOP=1 -q < "$BACKUP_FILE"

echo "Restore finished. Row counts:"
for table in hotel_bookings booking_events; do
  src=$(docker exec "$CONTAINER" psql -U "$DB_USER" -d "$SOURCE_DB" -tAc "SELECT COUNT(*) FROM $table;")
  dst=$(docker exec "$CONTAINER" psql -U "$DB_USER" -d "$RESTORE_DB" -tAc "SELECT COUNT(*) FROM $table;")
  echo "  $table: original=$src restored=$dst"
done