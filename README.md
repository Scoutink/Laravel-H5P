# Laravel H5P Pro

A comprehensive Laravel package for H5P interactive content with xAPI/LRS support.

## ✨ Features

- 📦 H5P Content Management (Create, Edit, Delete)
- 📚 Library Management
- 📊 Student Results Tracking
- 🔗 xAPI/LRS Integration
- 📈 Reports & Analytics
- 🎨 Tailwind CSS Admin Interface
- 🌍 Multi-language Support (EN, AR, FR)

## 📋 Requirements

- PHP 8.2+
- Laravel 11/12
- PostgreSQL/MySQL

## 🚀 Installation

### 1. Install via Composer

```bash
composer require djoudi/laravel-h5p
```

### 2. Run Installation Command

```bash
php artisan h5p:install
```

This will:
- Publish configuration files
- Run database migrations
- Create storage directories
- Link storage to public

### 3. Check Installation Status

```bash
php artisan h5p:status
```

## ⚙️ Configuration

### Environment Variables

Add to your `.env`:

```env
# H5P Settings
H5P_STORAGE_PATH=h5p

# LRS/xAPI Integration (Optional)
LRS_ENABLED=true
LRS_ENDPOINT=https://your-lrs.com/data/xAPI
LRS_USERNAME=your-key
LRS_PASSWORD=your-secret
```

## 📖 Available Commands

| Command | Description |
|---------|-------------|
| `php artisan h5p:install` | Full installation with migrations |
| `php artisan h5p:publish --force` | Republish assets and config |
| `php artisan h5p:cleanup --temp` | Clean temporary files |
| `php artisan h5p:cleanup --unused` | Remove unused libraries |
| `php artisan h5p:status` | Show installation status |

## 🔧 Usage

### Admin Routes

| Route | Description |
|-------|-------------|
| `/h5p/library` | Manage H5P libraries |
| `/admin/h5p` | Manage H5P content |
| `/admin/reports` | View reports |

### Student Routes

| Route | Description |
|-------|-------------|
| `/lesson/{id}` | View H5P content |

### Programmatic Usage

```php
use Illuminate\Support\Facades\App;

// Get H5P instance
$h5p = App::make('LaravelH5p');

// Get content
$content = $h5p->get_content($id);

// Get embed code
$embed = $h5p->get_embed($content, $settings);
```

## 🔗 xAPI/LRS Integration

When LRS is enabled, student results are automatically sent to your LRS:

1. Set `LRS_ENABLED=true` in `.env`
2. Configure LRS credentials
3. Run queue worker: `php artisan queue:work`

## 📁 Directory Structure

```
storage/app/public/h5p/
├── content/      # H5P content files
├── libraries/    # H5P libraries
└── temp/         # Temporary files
```

## 🧭 Deploying as Zip on Plesk (No Local Build)

You can deploy this branch directly from a GitHub zip upload:

1. Upload and extract this branch in Plesk `httpdocs`.
2. Deploy either by:
   - CLI script: `./scripts/auto_deploy_on_vps.sh`
   - Web UI: open `deploy-web/index.php` in browser and click **Run Deployment** (set `H5P_WEB_DEPLOY_PASSWORD` first)
3. Set document root to `httpdocs/public`.

See:

- `PLESK_DEPLOYMENT_MANUAL.txt` (step-by-step Plesk + phpMyAdmin guide)
- `docs/full-platform-integration.md` (what the script integrates internally)

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines.

## 📄 License

MIT License - see LICENSE file.
