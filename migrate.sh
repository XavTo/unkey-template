#!/bin/sh
set -eu

SCHEMA_URL="https://raw.githubusercontent.com/unkeyed/unkey/v2.0.48/pkg/db/schema.sql"
TMP="/tmp/schema.sql"

echo "Downloading schema..."
curl -fsSL "$SCHEMA_URL" -o "$TMP"

if mysql -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" \
  -e "SELECT 1 FROM information_schema.tables WHERE table_schema='${MYSQLDATABASE}' LIMIT 1" \
  >/dev/null 2>&1; then
  echo "Database already has tables, skipping schema import."
  exit 0
fi

echo "Applying schema..."
mysql -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" < "$TMP"

echo "Schema applied."
