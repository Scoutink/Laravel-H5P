# Full Laravel Platform Integration (No Local Build)

## What changed

This branch now supports a **zip-upload + one-command deploy** flow for Plesk.
You upload this repository zip, extract it in `httpdocs`, then deploy using either:

```bash
./scripts/auto_deploy_on_vps.sh
```

or web UI:

`deploy-web/index.php` (click **Run Deployment**)

Both paths execute the same deploy script and auto-build a full Laravel platform with this package.

## Why this is required

This repository is a Composer package (`type: library`), not a complete Laravel app.
So deployment must assemble a Laravel application and include this package as dependency.

## Integration details performed by the script

1. Creates Laravel `^12.0` project.
2. Copies this repo into `packages/laravel-h5p`.
3. Adds Composer `path` repository.
4. Requires `djoudi/laravel-h5p:@dev`.
5. Writes production `.env` with your MySQL values.
6. Runs:
   - `php artisan migrate --force`
   - `php artisan h5p:install`
   - `php artisan storage:link`
7. Runs Laravel optimization commands.
8. Publishes final app into your domain root.

## Required input at deploy time

- MySQL DB name
- MySQL username
- MySQL password
- Application URL


## Web deployer safety

Before using `deploy-web/index.php`, set `H5P_WEB_DEPLOY_PASSWORD` in Plesk environment variables.
This password is required by the page before it can start deployment.
