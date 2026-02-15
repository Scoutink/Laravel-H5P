# Full Laravel Platform Integration Guide (with Laravel H5P package)

This document explains exactly how to create a **full Laravel platform** and integrate this package into it.

## 1) Forensic analysis and architectural conclusion

`composer.json` in this repository defines:

- `"type": "library"`
- package name: `djoudi/laravel-h5p`
- Laravel provider auto-discovery metadata under `extra.laravel`

This confirms the repository is a package to be installed into a normal Laravel application, not deployed standalone as a website root.

---

## 2) Two supported integration modes

### Mode A (recommended): Local path package (best for custom edits)

Use when you want to modify package source and deploy those edits immediately.

1. Create Laravel app:
   ```bash
   composer create-project laravel/laravel:^12.0 laravel-h5p-platform
   ```
2. Copy this repository into app:
   ```bash
   mkdir -p laravel-h5p-platform/packages
   cp -a Laravel-H5P laravel-h5p-platform/packages/laravel-h5p
   ```
3. Register path repository:
   ```bash
   cd laravel-h5p-platform
   composer config repositories.laravel-h5p '{"type":"path","url":"packages/laravel-h5p","options":{"symlink":false}}'
   ```
4. Require package:
   ```bash
   composer require djoudi/laravel-h5p:@dev
   ```

### Mode B: Composer package from registry

Use when you do not need local source edits:

```bash
composer require djoudi/laravel-h5p
```

---

## 3) Automated builder script included in this repo

To reduce human error, use:

```bash
./scripts/build_full_platform.sh
```

What it does:

- creates Laravel 12 app,
- copies this package under `packages/laravel-h5p`,
- configures Composer path repository,
- installs the package,
- prepares `.env` and app key,
- creates deploy zip for Plesk upload.

Options:

```bash
./scripts/build_full_platform.sh --help
```

---

## 4) Post-integration Laravel configuration

Inside the generated Laravel app:

1. Configure MySQL in `.env`:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=your_db
   DB_USERNAME=your_user
   DB_PASSWORD=your_password
   ```

2. Run migrations and H5P installer:
   ```bash
   php artisan migrate --force
   php artisan h5p:install
   ```

3. Production optimization:
   ```bash
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

---

## 5) Health checklist

- Laravel home route loads without error.
- `php artisan about` succeeds.
- `php artisan h5p:status` succeeds.
- H5P tables exist in MySQL (`h5p_*`).
- `storage/app/public/h5p` exists and is writable.

