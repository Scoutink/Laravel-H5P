#!/usr/bin/env bash
set -euo pipefail

# Build a full Laravel platform and integrate this package as local path repository.
# Output is a deployable zip you can upload to Plesk.

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --app-name <name>      Laravel application directory name (default: laravel-h5p-platform)
  --laravel-version <v>  Laravel version constraint (default: ^12.0)
  --output-dir <dir>     Where to place generated app + zip (default: ./build)
  --skip-install         Skip composer create-project/install and only print next steps
  -h, --help             Show help
USAGE
}

APP_NAME="laravel-h5p-platform"
LARAVEL_VERSION="^12.0"
OUTPUT_DIR="$(pwd)/build"
SKIP_INSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name) APP_NAME="$2"; shift 2 ;;
    --laravel-version) LARAVEL_VERSION="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --skip-install) SKIP_INSTALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$OUTPUT_DIR/$APP_NAME"
PACKAGE_DIR="$APP_DIR/packages/laravel-h5p"
ZIP_PATH="$OUTPUT_DIR/${APP_NAME}-deploy.zip"

mkdir -p "$OUTPUT_DIR"

if [[ "$SKIP_INSTALL" -eq 1 ]]; then
  cat <<INFO
Skip mode enabled.

Next commands to run manually:
  composer create-project laravel/laravel:"$LARAVEL_VERSION" "$APP_DIR"
  mkdir -p "$APP_DIR/packages"
  cp -a "$REPO_ROOT" "$PACKAGE_DIR"
  cd "$APP_DIR"
  composer config repositories.laravel-h5p '{"type":"path","url":"packages/laravel-h5p","options":{"symlink":false}}'
  composer require djoudi/laravel-h5p:@dev
INFO
  exit 0
fi

if [[ -d "$APP_DIR" ]]; then
  echo "Error: target app directory already exists: $APP_DIR"
  exit 1
fi

echo "[1/7] Creating Laravel application in: $APP_DIR"
composer create-project laravel/laravel:"$LARAVEL_VERSION" "$APP_DIR"

echo "[2/7] Copying this package source into Laravel app"
mkdir -p "$APP_DIR/packages"
cp -a "$REPO_ROOT" "$PACKAGE_DIR"

# Keep generated app clean from nested git repo metadata.
rm -rf "$PACKAGE_DIR/.git"

echo "[3/7] Registering local path repository"
cd "$APP_DIR"
composer config repositories.laravel-h5p '{"type":"path","url":"packages/laravel-h5p","options":{"symlink":false}}'

echo "[4/7] Requiring package from local source"
composer require djoudi/laravel-h5p:@dev

echo "[5/7] Preparing Laravel app"
cp .env.example .env
php artisan key:generate

echo "[6/7] Installing production dependencies and optimizing"
composer install --no-dev --optimize-autoloader
php artisan optimize:clear

# Database-dependent commands intentionally omitted.
# Run these after setting DB_* values on target server:
#   php artisan migrate --force
#   php artisan h5p:install


echo "[7/7] Creating deployable zip: $ZIP_PATH"
rm -f "$ZIP_PATH"
(
  cd "$APP_DIR"
  zip -rq "$ZIP_PATH" .
)

echo "Done. Deployable package ready: $ZIP_PATH"
echo "IMPORTANT: Configure MySQL credentials in .env on the server, then run migrations + h5p install."
