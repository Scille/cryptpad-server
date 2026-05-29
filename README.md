# cryptpad-server

A Parsec-compatible distribution of [CryptPad](https://cryptpad.org) for self-hosted (on-premise) deployments.

This repository packages a specific version of CryptPad together with the customizations required for integration with [Parsec](https://parsec.cloud), and provides two installation methods: direct install (Node.js) and Docker.

## Prerequisites

- **Node.js** v20 or v22
- **npm** v10+
- **Git**
- Linux/macOS: `rsync`, `unzip`, `rdfind` (for the compression step — install via your package manager, see `Aptfile`)
- For OnlyOffice support: `unzip`

## Installation

### Method 1 — Direct install (Node.js)

**1. Clone this repository**

```bash
git clone https://github.com/Scille/cryptpad-server.git
cd cryptpad-server
```

**2. Install system dependencies** (Debian/Ubuntu)

```bash
sudo apt-get install -y $(cat Aptfile)
```

**3. Build**

```bash
# Full build including OnlyOffice
npm run build
```

The build script will:
- Clone the CryptPad source at the pinned commit
- Install Node.js dependencies
- Build frontend assets
- Install OnlyOffice (unless skipped)
- Copy the Parsec customizations from `./resources/` into the CryptPad directory

**4. Configure**

```bash
cp .env.example .env
# Edit .env and set at minimum CRYPTPAD_HTTP_UNSAFE_ORIGIN and CRYPTPAD_HTTP_SAFE_ORIGIN
```

**5. Start**

```bash
npm run start
```

The server listens on port `3000` by default.

**6. Keep the server running (production)**

Install [PM2](https://pm2.keymetrics.io/), a Node.js process manager that handles auto-restart and survives reboots:

```bash
npm install -g pm2

# Start
pm2 start cryptpad/server.js --name cryptpad

# Make it restart automatically on system boot
pm2 startup   # follow the printed instruction (one sudo command)
pm2 save

# Useful commands
pm2 status         # check running processes
pm2 logs cryptpad  # follow logs
pm2 restart cryptpad
pm2 stop cryptpad
```

> For Linux servers that prefer native systemd, an example unit file is available at `scripts/cryptpad-server.service`.

**7. Set up a reverse proxy with nginx (production)**

CryptPad requires **two separate domains** (main + sandbox) and needs TLS in production.
A ready-to-edit nginx config is provided at `scripts/nginx.example.conf`.

```bash
# Install nginx and certbot
sudo apt-get install -y nginx python3-certbot-nginx

# Copy and edit the example config
sudo cp scripts/nginx.example.conf /etc/nginx/sites-available/cryptpad
# Replace YOUR_MAIN_DOMAIN, YOUR_SANDBOX_DOMAIN and cert paths
sudo nano /etc/nginx/sites-available/cryptpad

sudo ln -s /etc/nginx/sites-available/cryptpad /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Obtain TLS certificates (replaces the cert placeholders automatically)
sudo certbot --nginx -d YOUR_MAIN_DOMAIN -d YOUR_SANDBOX_DOMAIN
```

Then set the matching values in your `.env`:

```bash
CRYPTPAD_HTTP_UNSAFE_ORIGIN=https://YOUR_MAIN_DOMAIN
CRYPTPAD_HTTP_SAFE_ORIGIN=https://YOUR_SANDBOX_DOMAIN
CRYPTPAD_HTTP_ADDRESS=127.0.0.1
```

Restart the service to apply: `sudo systemctl restart cryptpad-server`

---

### Method 2 — Docker

**Option A — Docker Compose (recommended)**

```bash
git clone https://github.com/Scille/cryptpad-server.git
cd cryptpad-server

cp .env.example .env
# Edit .env

docker compose up -d --build
```

Exposes ports `3000` (main) and `3003` (websocket). Named volumes for all persistent data are created automatically.

```bash
docker compose stop          # stop without removing the container
docker compose start         # restart the existing container
docker compose logs -f       # follow logs
docker compose down -v       # stop and delete volumes (destructive)
```

**Option B — Docker CLI**

```bash
# Build the image
docker build -t cryptpad-server .

# Run
docker run -d \
  --name cryptpad-server \
  --restart unless-stopped \
  -p 3000:3000 -p 3003:3003 \
  -v cryptpad_data:/app/cryptpad/data \
  -v cryptpad_datastore:/app/cryptpad/datastore \
  -v cryptpad_blob:/app/cryptpad/blob \
  -v cryptpad_block:/app/cryptpad/block \
  -v cryptpad_customize:/app/cryptpad/customize \
  -e CRYPTPAD_HTTP_UNSAFE_ORIGIN=https://cryptpad.example.com \
  -e CRYPTPAD_HTTP_SAFE_ORIGIN=https://cryptpad-sandbox.example.com \
  -e CRYPTPAD_HTTP_ADDRESS=0.0.0.0 \
  cryptpad-server
```

**Data persistence**

The following paths inside the container hold user data and must be persisted across container restarts:

| Path | Content |
|---|---|
| `/app/cryptpad/data` | Server state (user accounts, quota, etc.) |
| `/app/cryptpad/datastore` | Encrypted document storage |
| `/app/cryptpad/blob` | Binary files |
| `/app/cryptpad/block` | Login blocks |
| `/app/cryptpad/customize` | Runtime customizations |

Docker Compose creates named volumes for all of these automatically. With `docker run`, pass them as `-v` flags as shown above.

---

## Environment Variables

All variables are optional. Defaults are suited for local development (`localhost:3000`).

| Variable | Default | Description |
|---|---|---|
| `CRYPTPAD_HTTP_UNSAFE_ORIGIN` | `http://localhost:3000` | Main URL clients use to reach CryptPad |
| `CRYPTPAD_HTTP_SAFE_ORIGIN` | `http://safe.localhost:3000` | Sandbox URL (must be a different domain/subdomain in production) |
| `CRYPTPAD_HTTP_ADDRESS` | `localhost` | Address the Node.js server binds to (`0.0.0.0` to accept external connections) |
| `CRYPTPAD_CUSTOM_PROTOCOL` | `parsec-desktop:` | Custom protocol for Parsec CSP integration |
| `CRYPTPAD_MAX_WORKERS` | _(all cores)_ | Maximum number of worker processes |
| `CRYPTPAD_DATASTORE_PATH` | `./datastore` | Folder where cryptpad will store document |
| `CRYPTPAD_DATA_PATH` | `./data` | Folder where CryptPad will store its data |
| `CRYPTPAD_BLOCK_PATH` | `./block` | Folder where will reside users' authenticated blocks |
| `CRYPTPAD_BLOB_PATH` | `./blob` | Folder where are stored encrypted blob |
| `CRYPTPAD_LOG_PATH` | `{{ CRYPTPAD_DATA_PATH }}/logs` | Folder where log files are located
| `WEBSOCKET_PORT` | `3003` | The port the server use to listen to websocket |

> **Production note:** `CRYPTPAD_HTTP_SAFE_ORIGIN` must point to a **different domain or subdomain** than `CRYPTPAD_HTTP_UNSAFE_ORIGIN`. Using the same domain will break the CryptPad sandboxing model.

---

## Repository layout

```
resources/
  config/config.js        # CryptPad server configuration (env-var driven)
  customize/              # UI overrides (theme, branding, Parsec integration)
  www/frame.js            # Parsec iframe integration layer
  www/frame.html          # Host page for the iframe integration
  lib/                    # Server-side helpers
scripts/
  build.sh                # Entry point — detects OS and delegates
  build_unix.sh           # Linux/macOS build
  build_darwin.sh         # macOS build
  build_windows.sh        # Windows (Git Bash) build
  clone_cryptpad.sh       # Clones CryptPad at the pinned commit
  dev_start.sh            # Convenience script for local development
  cryptpad-server.service # systemd unit file for production
  nginx.example.conf      # nginx reverse proxy example config
```
