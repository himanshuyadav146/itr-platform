#!/usr/bin/env bash
# Replace XAMPP htdocs/api with apps/api from this repo, create local config,
# run marketplace DB bootstrap, and install admin + website frontends.
#
# Usage (from the repo root, Apache + MySQL already started in XAMPP):
#   ./scripts/setup-local-xampp.sh
#   ./scripts/setup-local-xampp.sh --start
set -euo pipefail

START_DEV=0
for arg in "$@"; do
  case "$arg" in
    --start) START_DEV=1 ;;
    -h|--help)
      echo "Usage: $0 [--start]"
      echo "  --start   also launch admin (:5173) and website (:5174)"
      exit 0
      ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/apps/api"

if [[ ! -d "$SRC" ]]; then
  echo "Could not find $SRC"
  exit 1
fi

detect_htdocs() {
  local candidates=(
    "/Applications/XAMPP/htdocs"
    "/Applications/XAMPP/xamppfiles/htdocs"
    "/opt/lampp/htdocs"
    "/Applications/LAMPP/htdocs"
  )
  local c
  for c in "${candidates[@]}"; do
    if [[ -d "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

detect_bin() {
  local name="$1"
  shift
  local c
  for c in "$@"; do
    if [[ -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi
  return 1
}

HTDOCS="$(detect_htdocs || true)"
if [[ -z "${HTDOCS:-}" ]]; then
  echo "Could not find XAMPP htdocs."
  echo "Expected one of: /Applications/XAMPP/htdocs or /Applications/XAMPP/xamppfiles/htdocs"
  exit 1
fi

DEST="$HTDOCS/api"
echo "Repo API source : $SRC"
echo "XAMPP htdocs    : $HTDOCS"
echo "Deploy target   : $DEST"

PHP_BIN="$(detect_bin php \
  /Applications/XAMPP/xamppfiles/bin/php \
  /Applications/XAMPP/bin/php \
  /opt/lampp/bin/php || true)"
MYSQL_BIN="$(detect_bin mysql \
  /Applications/XAMPP/xamppfiles/bin/mysql \
  /Applications/XAMPP/bin/mysql \
  /opt/lampp/bin/mysql || true)"

if [[ -z "${PHP_BIN:-}" ]]; then
  echo "PHP not found. Use XAMPP's php binary."
  exit 1
fi
if [[ -z "${MYSQL_BIN:-}" ]]; then
  echo "mysql client not found. Start MySQL in XAMPP and retry."
  exit 1
fi

echo "PHP             : $PHP_BIN"
echo "MySQL           : $MYSQL_BIN"

extract_php_string() {
  local file="$1"
  local var="$2"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$file" "$var" <<'PY'
import re, sys
path, var = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8", errors="ignore").read()
m = re.search(r"\$%s\s*=\s*['\"]([^'\"]*)['\"]" % re.escape(var), text)
print(m.group(1) if m else "")
PY
    return
  fi
  grep -E "^\s*\$${var}\s*=" "$file" | head -1 | sed -E "s/.*['\"]([^'\"]*)['\"].*/\1/"
}

DB_USER="root"
DB_PASS=""
DB_NAME="itr_services"
PRESERVE_CONFIG=""
PRESERVE_PAYMENT=""
PRESERVE_FIREBASE=""

if [[ -f "$DEST/include/config.php" ]]; then
  echo "Keeping existing htdocs/api/include/config.php credentials."
  PRESERVE_CONFIG="$(mktemp)"
  cp "$DEST/include/config.php" "$PRESERVE_CONFIG"
  parsed_user="$(extract_php_string "$PRESERVE_CONFIG" username || true)"
  parsed_pass="$(extract_php_string "$PRESERVE_CONFIG" password || true)"
  parsed_db="$(extract_php_string "$PRESERVE_CONFIG" database || true)"
  [[ -n "$parsed_user" ]] && DB_USER="$parsed_user"
  DB_PASS="$parsed_pass"
  [[ -n "$parsed_db" ]] && DB_NAME="$parsed_db"
fi
if [[ -f "$DEST/include/payment_config.php" ]]; then
  PRESERVE_PAYMENT="$(mktemp)"
  cp "$DEST/include/payment_config.php" "$PRESERVE_PAYMENT"
fi
if [[ -f "$DEST/include/firebase_config.php" ]]; then
  PRESERVE_FIREBASE="$(mktemp)"
  cp "$DEST/include/firebase_config.php" "$PRESERVE_FIREBASE"
fi

if ! MYSQL_PWD="$DB_PASS" "$MYSQL_BIN" -u "$DB_USER" -e "SELECT 1" >/dev/null 2>&1; then
  echo "Cannot connect to MySQL as '$DB_USER'."
  echo "Start Apache + MySQL in XAMPP, then re-run."
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
if [[ -e "$DEST" ]]; then
  BACKUP="$HTDOCS/api.bak.$STAMP"
  echo "Moving old $DEST -> $BACKUP"
  mv "$DEST" "$BACKUP"
fi

mkdir -p "$DEST"
if command -v rsync >/dev/null 2>&1; then
  rsync -a \
    --exclude vendor \
    --exclude include/config.php \
    --exclude include/payment_config.php \
    --exclude include/firebase_config.php \
    --exclude uploads \
    --exclude '.git*' \
    "$SRC/" "$DEST/"
else
  cp -R "$SRC/." "$DEST/"
  rm -rf "$DEST/vendor" "$DEST/include/config.php" "$DEST/include/payment_config.php"
fi

mkdir -p "$DEST/uploads"
if [[ -f "$SRC/uploads/.htaccess" ]]; then
  cp "$SRC/uploads/.htaccess" "$DEST/uploads/.htaccess"
fi
if [[ -n "${BACKUP:-}" && -d "$BACKUP/uploads" ]]; then
  cp -R "$BACKUP/uploads/." "$DEST/uploads/" 2>/dev/null || true
fi
chmod 777 "$DEST/uploads" || true

if [[ -n "$PRESERVE_CONFIG" ]]; then
  cp "$PRESERVE_CONFIG" "$DEST/include/config.php"
  rm -f "$PRESERVE_CONFIG"
else
  cp "$SRC/include/config.local.php.example" "$DEST/include/config.php"
fi

if [[ -n "$PRESERVE_PAYMENT" ]]; then
  cp "$PRESERVE_PAYMENT" "$DEST/include/payment_config.php"
  rm -f "$PRESERVE_PAYMENT"
else
  cp "$SRC/include/payment_config.php.example" "$DEST/include/payment_config.php"
fi

if [[ -n "$PRESERVE_FIREBASE" ]]; then
  cp "$PRESERVE_FIREBASE" "$DEST/include/firebase_config.php"
  rm -f "$PRESERVE_FIREBASE"
fi

# Keep repo working copy usable too (same local config).
if [[ ! -f "$SRC/include/config.php" ]]; then
  cp "$DEST/include/config.php" "$SRC/include/config.php"
fi
if [[ ! -f "$SRC/include/payment_config.php" ]]; then
  cp "$DEST/include/payment_config.php" "$SRC/include/payment_config.php"
fi

echo "Creating database '$DB_NAME' if needed..."
MYSQL_PWD="$DB_PASS" "$MYSQL_BIN" -u "$DB_USER" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "Installing Composer packages (Razorpay/Paytm)..."
COMPOSER_BIN=""
if command -v composer >/dev/null 2>&1; then
  COMPOSER_BIN="composer"
elif [[ -f "$DEST/composer.phar" ]]; then
  COMPOSER_BIN="$PHP_BIN $DEST/composer.phar"
else
  echo "Downloading composer.phar..."
  (
    cd "$DEST"
    "$PHP_BIN" -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    "$PHP_BIN" composer-setup.php --install-dir="$DEST" --filename=composer.phar
    rm -f composer-setup.php
  )
  COMPOSER_BIN="$PHP_BIN $DEST/composer.phar"
fi

if ! (cd "$DEST" && $COMPOSER_BIN install --no-interaction --no-dev --optimize-autoloader); then
  echo "WARNING: composer install failed. Associate list/approvals still work; Razorpay checkout may not."
fi

echo "Bootstrapping schema + demo users..."
"$PHP_BIN" "$DEST/migrations/bootstrap_local.php"

echo "Writing local frontend env (empty base URL = Vite proxy to http://localhost/api)..."
cat > "$ROOT/apps/admin/.env.local" <<'EOF'
VITE_API_BASE_URL=
EOF
cat > "$ROOT/apps/itr_web/FINAPP/.env.local" <<'EOF'
VITE_API_BASE_URL=
VITE_ENABLE_DEBUG=true
EOF

if command -v npm >/dev/null 2>&1; then
  echo "Installing admin npm packages..."
  (cd "$ROOT/apps/admin" && npm install)
  echo "Installing website npm packages..."
  (cd "$ROOT/apps/itr_web/FINAPP" && npm install)
else
  echo "WARNING: npm not found. Install Node.js 18+, then:"
  echo "  cd $ROOT/apps/admin && npm install && npm run dev"
  echo "  cd $ROOT/apps/itr_web/FINAPP && npm install && npm run dev"
fi

if [[ "$START_DEV" -eq 1 ]]; then
  if ! command -v npm >/dev/null 2>&1; then
    echo "Cannot --start without npm."
    exit 1
  fi
  LOG_DIR="$ROOT/.local-dev-logs"
  mkdir -p "$LOG_DIR"
  echo "Starting Vite admin on :5173 and website on :5174..."
  (cd "$ROOT/apps/admin" && npm run dev -- --host 127.0.0.1 --port 5173) >"$LOG_DIR/admin.log" 2>&1 &
  echo $! > "$LOG_DIR/admin.pid"
  (cd "$ROOT/apps/itr_web/FINAPP" && npm run dev -- --host 127.0.0.1 --port 5174) >"$LOG_DIR/web.log" 2>&1 &
  echo $! > "$LOG_DIR/web.pid"
fi

echo
echo "=========================================="
echo " Local setup complete"
echo "=========================================="
echo "API          http://localhost/api/test_connection.php"
echo "phpMyAdmin   http://localhost/phpmyadmin"
echo "Admin UI     http://localhost:5173/admin/"
echo "Website      http://localhost:5174/services"
echo
echo "Logins (local demo):"
echo "  Admin              admin@example.com / password123"
echo "  Client             client@example.com / password123"
echo "  Associate pending  priya.ca@example.com / password123"
echo "  Associate approved rahul.ca@example.com / password123"
echo
if [[ "$START_DEV" -eq 0 ]]; then
  echo "Start the UIs (two Terminal tabs):"
  echo "  cd $ROOT/apps/admin && npm run dev"
  echo "  cd $ROOT/apps/itr_web/FINAPP && npm run dev"
fi
echo
echo "Old htdocs/api was moved aside (api.bak.*) if it existed."
echo "Re-run this script after pulling new PHP changes."
