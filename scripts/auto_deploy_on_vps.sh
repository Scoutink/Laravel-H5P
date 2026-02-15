#!/usr/bin/env bash
set -euo pipefail

# One-command deploy helper for Plesk VPS after uploading THIS repository zip.
# It builds a full Laravel app in the current directory and integrates this package.

if [[ ! -f composer.json ]]; then
  echo "Run this script from the extracted Laravel-H5P repository root."
  exit 1
fi

DOMAIN_ROOT="$(pwd)"
WORKDIR="$DOMAIN_ROOT/.build-laravel-h5p-platform"
APP_DIR="$WORKDIR/app"
PACKAGE_DST="$APP_DIR/packages/laravel-h5p"

read -rp "MySQL database name: " DB_NAME
read -rp "MySQL username: " DB_USER
read -rsp "MySQL password: " DB_PASS
echo
read -rp "App URL (e.g. https://example.com): " APP_URL

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

echo "[1/8] Creating Laravel 12 project"
composer create-project laravel/laravel:^12.0 "$APP_DIR"

echo "[2/8] Copying package source"
mkdir -p "$APP_DIR/packages"
rsync -a --delete --exclude '.git' --exclude 'vendor' --exclude 'build' --exclude '.build-laravel-h5p-platform' "$DOMAIN_ROOT/" "$PACKAGE_DST/"

echo "[3/8] Wiring local package repository"
cd "$APP_DIR"
composer config repositories.laravel-h5p '{"type":"path","url":"packages/laravel-h5p","options":{"symlink":false}}'
composer require djoudi/laravel-h5p:@dev

echo "[4/8] Configuring environment"
cp .env.example .env
php artisan key:generate
php -r "
file_put_contents('.env', preg_replace([
'/^APP_ENV=.*/m',
'/^APP_DEBUG=.*/m',
'/^APP_URL=.*/m',
'/^DB_CONNECTION=.*/m',
'/^DB_HOST=.*/m',
'/^DB_PORT=.*/m',
'/^DB_DATABASE=.*/m',
'/^DB_USERNAME=.*/m',
'/^DB_PASSWORD=.*/m'
], [
'APP_ENV=production',
'APP_DEBUG=false',
'APP_URL={$argv[1]}',
'DB_CONNECTION=mysql',
'DB_HOST=127.0.0.1',
'DB_PORT=3306',
'DB_DATABASE={$argv[2]}',
'DB_USERNAME={$argv[3]}',
'DB_PASSWORD={$argv[4]}'
], file_get_contents('.env')));" "$APP_URL" "$DB_NAME" "$DB_USER" "$DB_PASS"

echo "[5/8] Installing production dependencies"
composer install --no-dev --optimize-autoloader

echo "[6/8] Running migrations + H5P installation"
php artisan migrate --force
php artisan h5p:install
php artisan storage:link || true

echo "[7/8] Optimizing"
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "[8/8] Publishing app to domain root"
find "$DOMAIN_ROOT" -mindepth 1 -maxdepth 1 ! -name '.build-laravel-h5p-platform' -exec rm -rf {} +
cp -a "$APP_DIR"/. "$DOMAIN_ROOT"/
rm -rf "$WORKDIR"

echo "Deployment completed. Ensure Plesk document root points to httpdocs/public"
