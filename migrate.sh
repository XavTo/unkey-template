#!/bin/sh
set -eu

SCHEMA_URL="https://raw.githubusercontent.com/unkeyed/unkey/v2.0.48/pkg/db/schema.sql"
TMP="/tmp/schema.sql"

echo "Downloading schema..."
curl -fsSL "$SCHEMA_URL" -o "$TMP"

echo "Checking if DB already initialized..."
HAS_TABLES="$(mysql -N -s -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" \
  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MYSQLDATABASE}'")"

if [ "${HAS_TABLES}" -eq 0 ]; then
  echo "Applying schema..."
  mysql -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" < "$TMP"
  echo "Schema applied."
else
  echo "Schema already present."
fi

# --- SEED ROOT KEY (self-host bootstrap) ---

: "${UNKEY_ROOT_KEY:?UNKEY_ROOT_KEY is required in db-init service}"

WORKSPACE_ID="ws_railway"
ORG_ID="org_railway"
KEYAUTH_ID="keyauth_railway"

ROOT_KEY_ID="key_root"
PERM_ID="perm_api_create_api"
ROOT_KEY_NAME="root"

ROOT_KEY_HASH="$(printf '%s' "$UNKEY_ROOT_KEY" | sha256sum | awk '{print $1}')"
ROOT_KEY_START="$(printf '%s' "$UNKEY_ROOT_KEY" | cut -c1-8)"

echo "Seeding workspace/keyauth/root key..."

mysql -h "$MYSQLHOST" -P "$MYSQLPORT" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" <<SQL
-- Workspace minimal (features/beta_features requis car NOT NULL)
INSERT INTO workspaces (
  id, org_id, name, slug,
  beta_features, features,
  enabled, created_at_m
)
VALUES (
  '${WORKSPACE_ID}', '${ORG_ID}', 'Railway', 'railway',
  JSON_OBJECT(), JSON_OBJECT(),
  true, 0
)
ON DUPLICATE KEY UPDATE id = id;

-- Key auth minimal
INSERT INTO key_auth (
  id, workspace_id, store_encrypted_keys, created_at_m
)
VALUES (
  '${KEYAUTH_ID}', '${WORKSPACE_ID}', false, 0
)
ON DUPLICATE KEY UPDATE id = id;

-- Permission requise par apis.createApi: api.*.create_api
INSERT INTO permissions (
  id, workspace_id, name, slug, description, created_at_m
)
VALUES (
  '${PERM_ID}', '${WORKSPACE_ID}',
  'Create APIs', 'api.*.create_api',
  'Allows creating API namespaces', 0
)
ON DUPLICATE KEY UPDATE id = id;

-- Root key (stockée par hash)
INSERT INTO keys (
  id, key_auth_id, hash, start,
  workspace_id, for_workspace_id,
  name, enabled, created_at_m
)
VALUES (
  '${ROOT_KEY_ID}', '${KEYAUTH_ID}', '${ROOT_KEY_HASH}', '${ROOT_KEY_START}',
  '${WORKSPACE_ID}', '${WORKSPACE_ID}',
  '${ROOT_KEY_NAME}', true, 0
)
ON DUPLICATE KEY UPDATE
  hash = VALUES(hash),
  start = VALUES(start),
  enabled = true;

-- Attacher la permission à la root key
INSERT INTO keys_permissions (
  key_id, permission_id, workspace_id, created_at_m
)
VALUES (
  '${ROOT_KEY_ID}', '${PERM_ID}', '${WORKSPACE_ID}', 0
)
ON DUPLICATE KEY UPDATE key_id = key_id;
SQL

echo "Done."
