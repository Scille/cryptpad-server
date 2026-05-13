#! /bin/bash

# Less strict settings for local development - don't exit on every error
set -eu

echo "🪟 Building CryptPad for Windows development..."



# Parse command line arguments
PRUNE=true
INSTALL_OO=true

show_help() {
    cat << EOF
Usage: npm run build [-- OPTIONS]

Local Windows development build script for CryptPad.

OPTIONS:
    --no-prune         Skip npm prune operations (dev dependencies stay installed)
    --no-install-oo    Skip OnlyOffice installation (recommended for faster local builds)
    --help, -h         Show this help message and exit

EXAMPLES:
    npm run build                        # Full build with OnlyOffice
    npm run build -- --no-install-oo    # Fast local build (recommended)

NOTES:
    - This script is optimized for Windows local development
    - Errors are less strict than production builds
    - Streamlined for faster Windows builds
    - Use Git Bash, MSYS2, or similar Unix-like environment on Windows

EOF
}

for arg in "$@"; do
    case $arg in
        --no-prune)
            PRUNE=false
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
    # Clean node_modules for a fresh start
    npm prune
fi

# Install dependencies
npm clean-install --production=false --unsafe-perm

npm run install:components

# Needed to rebuild frontend assets
npm run build
if [ -f "www/common/config.js" ]; then
    sed -i "s/cacheVersion:.*/cacheVersion: $(date +%s),/" www/common/config.js
fi

if [ "$INSTALL_OO" = true ]; then
    echo "📦 Installing OnlyOffice (this may take a while)..."
    # Unzip is too verbose by default, make it quiet
    sed -is 's#unzip \(.*\.zip\)#unzip -q \1#' install-onlyoffice.sh
    ./install-onlyoffice.sh --accept-license --no-rdfind
    echo "✅ OnlyOffice installation completed"
    echo "📁 www directory ready"
fi

if [ "$PRUNE" = true ]; then
    echo "🧹 Pruning production dependencies..."
    npm prune --production
    echo "   ✅ Dependencies pruned"
fi

popd

# Copy resources to cryptpad directory
echo "📋 Copying configuration files..."
cp -r ./resources/* ./cryptpad/
echo "   ✅ Configuration files copied"

echo ""
echo "🎉 CryptPad Windows build completed successfully!"
echo ""
echo "Next steps:"
echo "  1. cd cryptpad"
echo "  2. npm start (starts CryptPad on http://localhost:3000)"
echo "  3. Open http://localhost:3000 in your browser"
echo ""
echo "Development options:"
echo "  HTTP mode:"
echo "    1. npm run dev (from project root)"
echo "    2. Open http://localhost:3000"
echo ""
echo "Windows-specific notes:"
echo "  - Make sure Windows Defender/antivirus isn't blocking Node.js"
