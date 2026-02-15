# Full Laravel Platform Integration (No Local Build)

## What changed

This branch now supports a **zip-upload + one-command deploy** flow for Plesk.
You upload this repository zip, extract it in `httpdocs`, and run:

```bash
./scripts/auto_deploy_on_vps.sh
```

That script auto-builds a full Laravel platform and installs this package into it.

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

