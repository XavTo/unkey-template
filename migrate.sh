#!/bin/sh
set -eu

SCHEMA_URL="https://raw.githubusercontent.com/unkeyed/unkey/v2.0.48/pkg/db/schema.sql"
TMP="/tmp/schema.sql"

echo "Downloading schema..."
curl -fsSL "$SCHEMA_URL" -o "$TMP"

echo "Checking if DB already initialized..."
HAS_TABLES="$(mysql -N -s -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" \
  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MYSQLDATABASE}'")"

if [ "${HAS_TABLES}" -gt 0 ]; then
  echo "Database already initialized; nothing to do."
  exit 0
fi

echo "Applying schema..."
mysql -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" < "$TMP"

echo "Done."
