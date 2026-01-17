#!/bin/sh
set -eu

# Unkey MySQL schema (tag pinned to your image version)
SCHEMA_URL="https://raw.githubusercontent.com/unkeyed/unkey/v2.0.48/pkg/db/schema.sql"
TMP="/tmp/schema.sql"

# Safety checks (fail fast with clear logs)
: "${MYSQLHOST:?MYSQLHOST not set}"
: "${MYSQLPORT:?MYSQLPORT not set}"
: "${MYSQLUSER:?MYSQLUSER not set}"
: "${MYSQLPASSWORD:?MYSQLPASSWORD not set}"
: "${MYSQLDATABASE:?MYSQLDATABASE not set}"

echo "Downloading schema..."
curl -fsSL "$SCHEMA_URL" -o "$TMP"

echo "Target DB: ${MYSQLUSER}@${MYSQLHOST}:${MYSQLPORT}/${MYSQLDATABASE}"

echo "Checking if Unkey schema exists (table: apis)..."
HAS_APIS="$(mysql -N -s \
  -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" \
  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MYSQLDATABASE}' AND table_name='apis';")"

if [ "${HAS_APIS:-0}" -gt 0 ]; then
  echo "Unkey schema already present; nothing to do."
  echo "Current tables:"
  mysql -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" -e "SHOW TABLES;" || true
  exit 0
fi

echo "Applying schema..."
mysql -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" < "$TMP"

echo "Schema applied. Tables now:"
mysql -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" -e "SHOW TABLES;"

echo "Done."
