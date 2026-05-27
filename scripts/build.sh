#!/bin/bash

# Common build script that detects OS and redirects to appropriate build script

set -e

# Detect operating system for cross-platform compatibility
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

OS=$(detect_os)
echo "🔍 Detected OS: $OS"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$OS" in
    "windows")
        echo "🪟 Using Windows build script..."
        exec "$SCRIPT_DIR/build_windows.sh" "$@"
        ;;
    "linux")
        echo "🐧 Using Unix build script..."
        exec "$SCRIPT_DIR/build_unix.sh" "$@"
        ;;
    "macos")
        echo "🐧 Using Darwin build script..."
        sh "$SCRIPT_DIR/build_darwin.sh" "$@"
        ;;
    *)
        echo "❌ Error: Unsupported operating system: $OS"
        echo ""
        echo "💡 Supported platforms:"
        echo "   - Linux (detected as 'linux')"
        echo "   - macOS (detected as 'macos')" 
        echo "   - Windows with Git Bash/MSYS2 (detected as 'windows')"
        echo ""
        echo "   If you're on a supported platform but seeing this error,"
        echo "   make sure you're running this script from the appropriate environment."
        exit 1
        ;;
esac
