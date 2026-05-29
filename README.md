# cryptpad-server

[![Build cryptpad](https://github.com/Scille/cryptpad-server/actions/workflows/build.yml/badge.svg)](https://github.com/Scille/cryptpad-server/actions/workflows/build.yml) [![Build & Publish docker cryptpad](https://github.com/Scille/cryptpad-server/actions/workflows/docker-cryptpad.yml/badge.svg)](https://github.com/Scille/cryptpad-server/actions/workflows/docker-cryptpad.yml) ![GitHub Release](https://img.shields.io/github/v/release/Scille/cryptpad-server?display_name=release&style=flat&logoSize=auto)

A Parsec-compatible distribution of [CryptPad](https://cryptpad.org) for self-hosted (on-premise) deployments.

This repository packages a specific version of CryptPad together with the customizations required for integration with [Parsec](https://parsec.cloud), and provides two installation methods: direct install (Node.js) and Docker.

## Install

We recommend that you install CryptPad using Docker

```bash
docker pull ghcr.io/scille/cryptpad-server/cryptpad:latest
```

### Install Without Docker

- Download our built server from [the latest release](https://github.com/Scille/cryptpad-server/releases/latest):

  Download the asset `cryptpad-server.zip` from the release:

  You can use [GitHub CLI](https://cli.github.com/) to download the archive from the latest release:

  ```bash
  gh release download --pattern cryptpad-server.zip 
  ```

  Once the archive obtained, extract it:

  ```bash
  unzip -d cryptpad cryptpad-server.zip
  ```

- [Manually build the server from the sources](#build-from-sources)

## Startup with Docker

1. [Configure the env variables file](#configure-env-variables-file)

2. Start the container with:

   ```bash
   docker run -d \
     --name cryptpad-server \
     --restart unless-stopped \
     -p 3000:3000 -p 3003:3003 \
     -v cryptpad_data:/app/cryptpad/data \
     -v cryptpad_datastore:/app/cryptpad/datastore \
     -v cryptpad_blob:/app/cryptpad/blob \
     -v cryptpad_block:/app/cryptpad/block \
     -v cryptpad_customize:/app/cryptpad/customize \
     --env-file .env \
      ghcr.io/scille/cryptpad-server/cryptpad:latest
   ```

> [!NOTE]
> The command configure some [paths that need to be presisted](#data-persistence)

## Startup with Docker Compose

1. [Configure the env variables file](#configure-env-variables-file)

2. We provide a minimal `docker-compose` stack here: [docker-compose.yml](./docker-compose.yml).

   ```bash
   docker compose -f ./docker-compose.yml up
   ```

   The stack will expose the service through the port `3000` (main) and `3003` (websocket) by default.

   > [!NOTE]
   > The stack will automatically create volume for the [data that need to be made persistent](#data-persistence)

## Startup Without Docker

1. [Configure the env variables file](#configure-env-variables-file)

1. Go into the `cryptpad` directory

   ```bash
   cd cryptpad
   ```

   > [!NOTE]
   > You obtained the `cryptpad` directory after following the instructions to [install CryptPad without Docker](#install-without-docker).

2. Start the server:

   You can either:

   - Do it with `npm`:
     
     ```bash
     npm run start
     ```

   - Or directly with `nodejs`:

     ```bash
     node server.js
     ```

For a more permanent solution, you can use [PM2](https://pm2.keymetrics.io/) to manage the process:

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

We also provide a systemd unit file as an example that can be found here: [`scripts/cryptpad-server.service`](./scripts/cryptpad-server.service).

## Build from Sources

### Build Prerequisites

- **Node.js** v22
- **npm** v10+
- **Git**
- Linux/macOS: `rsync`, `unzip`, `rdfind` 

  If you're on a Linux disto similar to Debian/Ubuntu, we provide an [Aptfile](./Aptfile) with the dependencies
  
  ```bash
  sudo apt-get install -y $(cat Aptfile)
  ```

- For OnlyOffice support: `unzip`

### Build Steps

1. Ensure you fill the build's prerequisites
2. Clone this repository

   ```bash
   git clone https://github.com/Scille/cryptpad-server.git
   cd cryptpad-server
   ```

3. Build

   ```bash
   npm run build
   ```

   The build script will:
   - Clone the CryptPad source at the pinned commit
   - Install Node.js dependencies
   - Build frontend assets
   - Install OnlyOffice (unless skipped)
   - Copy the Parsec customizations from `./resources/` into the CryptPad directory (`./cryptpad`)

## Build Using Docker

### Build Using Docker - Prerequisites

- **Git**
- **Docker**

### Build Using Docker - Steps

Build the Docker image from sources:

1. Clone this repository:

   ```bash
   git clone https://github.com/Scille/cryptpad-server.git
   ```

2. Build using Docker:

   ```bash
   docker build -t cryptpad-server .
   ```

   > [!NOTE]
   > We build the image and assign it the tag `cryptpad-server`, feel free to change it and/or add tags.

## Configure Env Variables File

CryptPad needs some env variables to be able to work correctly and to customize it.

We provide an [example env file](./.env.example) which provide a start point:

```bash
cp .env.example .env
```

But you need to edit that file to set at least

- `CRYPTPAD_HTTP_UNSAFE_ORIGIN`
- `CRYPTPAD_HTTP_SAFE_ORIGIN`

### Environment Variables

All variables are optional. Defaults are suited for local development (`localhost:3000`).

| Variable                      | Default                         | Description |
| ----------------------------- | ------------------------------- |--- |
| `PORT`                        | `3000`                          | Port the server will listen to |
| `WEBSOCKET_PORT`              | `3003`                          | The port the server use to listen to websocket |
| `CRYPTPAD_HTTP_UNSAFE_ORIGIN` | `http://localhost:3000`         | Main URL clients use to reach CryptPad |
| `CRYPTPAD_HTTP_SAFE_ORIGIN`   | `http://safe.localhost:3000`    | Sandbox URL (must be a different domain/subdomain in production) |
| `CRYPTPAD_HTTP_ADDRESS`       | `localhost`                     | Address the Node.js server binds to (`0.0.0.0` to accept external connections) |
| `CRYPTPAD_CUSTOM_PROTOCOL`    | `parsec-desktop:`               | Custom protocol for Parsec CSP integration |
| `CRYPTPAD_MAX_WORKERS`        | _(all cores)_                   | Maximum number of worker processes |
| `CRYPTPAD_DATASTORE_PATH`     | `./datastore`                   | Folder where cryptpad will store document |
| `CRYPTPAD_DATA_PATH`          | `./data`                        | Folder where CryptPad will store its data |
| `CRYPTPAD_BLOCK_PATH`         | `./block`                       | Folder where will reside users' authenticated blocks |
| `CRYPTPAD_BLOB_PATH`          | `./blob`                        | Folder where are stored encrypted blob |
| `CRYPTPAD_LOG_PATH`           | `{{ CRYPTPAD_DATA_PATH }}/logs` | Folder where log files are located |

> [!IMPORTANT]
>
> `CRYPTPAD_HTTP_SAFE_ORIGIN` must point to a **different domain or subdomain** than `CRYPTPAD_HTTP_UNSAFE_ORIGIN`. 
>
> Using the same domain will break the CryptPad sandboxing model.

### Data Persistence

The following paths need to be persisted across restarts:

| Path                                        | Content |
| ------------------------------------------- | --- |
| `CRYPTPAD_DATA_PATH`                        | Server state (user accounts, quota, etc.) |
| `CRYPTPAD_DATASTORE_PATH`                   | Encrypted document storage |
| `CRYPTPAD_BLOB_PATH`                        | Binary files |
| `CRYPTPAD_BLOCK_PATH`                       | Login blocks |
| `./customize` (relative to cryptpad folder) | Runtime customizations |

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
