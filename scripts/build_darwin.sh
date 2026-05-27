#! /bin/bash

set -eux

echo "🐧 Building CryptPad for macOS..."

# Parse command line arguments
PRUNE=true
COMPRESS=true
INSTALL_OO=true

show_help() {
    cat << EOF
Usage: npm run build [-- OPTIONS]

Build script for cryptpad-server (macOS).

OPTIONS:
    --no-prune         Skip npm prune operations (dev dependencies stay installed)
    --no-compress      Skip compression and rdfind operations for `cryptpad/www` resources
    --no-install-oo    Skip OnlyOffice installation
    --help, -h         Show this help message and exit

EXAMPLES:
    npm run build                              # Run full build with all optimizations
    npm run build -- --no-compress            # Build without compression for faster development
    npm run build -- --no-prune --no-compress # Skip both pruning and compression

EOF
}

for arg in "$@"; do
    case $arg in
        --no-prune)
            PRUNE=false
            shift
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        --no-install-oo)
            INSTALL_OO=false
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Clone cryptpad repository (single source of truth for commit hash)
if ! bash scripts/clone_cryptpad.sh; then
    echo "❌ Failed to execute clone_cryptpad.sh. Aborting."
    exit 1
fi

# Verify the cloned repository exists
if [ ! -d "cryptpad" ]; then
    echo "❌ 'cryptpad' directory not found after cloning. Aborting."
    exit 1
fi
echo "✅ CryptPad repository cloned successfully."

pushd cryptpad

if [ "$PRUNE" = true ]; then
    npm prune
fi

npm clean-install --production=false --unsafe-perm

npm run install:components

# Needed to rebuild frontend assets
npm run build
if [ -f "www/common/config.js" ]; then
    sed -i "s/cacheVersion:.*/cacheVersion: $(date +%s),/" www/common/config.js
fi

if [ "$INSTALL_OO" = true ]; then
    # Unzip is too verbose by default, make it quiet
    sed -is 's#unzip \(.*\.zip\)#unzip -q \1#' install-onlyoffice.sh
    ./install-onlyoffice.sh --accept-license --no-rdfind
    du -sh ./www
fi

if [ "$COMPRESS" = true ]; then
    # TODO: currently doesn't work since symlink end up being absolute

    # Step 1: Compress resources since the server is able to serve them
    # as-is with a `Content-Encoding: gzip`.

    # TODO: The server seems to struggle to server some formats...
    # Skip:
    # - png/jpeg/gif/woff/br/...: already compressed format
    # - html: compression messes with redirection (i.e. GET /foo -> 301 /foo/index.html)
    TO_COMPRESS_FORMATS='\.(js|css|json|svg|xml|scss|less|md|idx|dic)$'

    # Note the `--no-name` in gzip, this is to make the compression deterministic
    # which is important for the next step...
    find ./www -type f | grep -E $TO_COMPRESS_FORMATS | xargs -P 0 -I % gzip --no-name %

    du -sh ./www

    # Step 2: Detect duplications in resources and symlink them

    rdfind -makehardlinks true -makeresultsfile false ./www/
    du -sh ./www
fi

du -sh ./node_modules
if [ "$PRUNE" = true ]; then
    npm prune --production
    du -sh ./node_modules
fi

popd

rsync --archive --verbose ./resources/ ./cryptpad/
