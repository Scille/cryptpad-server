#!/bin/bash

# CryptPad development server script

echo "🚀 Starting CryptPad"
echo "==============================="

# Pure HTTP mode only

echo ""

# Always install dependencies to make sure everything is up to date
echo "📦 Installing dependencies..."
npm install

echo "✅ Dependencies installed"



# Build CryptPad if needed
if [ ! -d cryptpad/www ]; then
    echo "🏗️  Building CryptPad..."
    npm run build -- --no-install-oo
fi

cp resources/www/frame.* cryptpad/www/.

echo "🌐 HTTP mode - CryptPad will run on localhost:3000"

echo ""
echo "🔥 Starting services..."

# Function to handle cleanup
cleanup() {
    echo ""
    echo "🛑 Stopping CryptPad..."
    kill $CRYPTPAD_PID 2>/dev/null
    exit 0
}

# Kill any existing processes on the ports we need (Windows compatible)
echo "🧹 Stopping any existing processes on ports 3000-3004..."
for port in 3000 3001 3003; do
    netstat -ano | findstr ":$port " | awk '{print $5}' | xargs -r taskkill //PID //F 2>/dev/null || true
done

# Start CryptPad
echo "1️⃣  Starting CryptPad..."
cd cryptpad
# Pass environment variables to CryptPad
echo "🔧 Debug: Pure HTTP mode"
env \
  PORT="${PORT:-3000}" \
  CRYPTPAD_HTTP_ADDRESS="${CRYPTPAD_HTTP_ADDRESS:-localhost}" \
  CRYPTPAD_CUSTOM_PROTOCOL="${CRYPTPAD_CUSTOM_PROTOCOL:-vector:}" \
  npm start &
CRYPTPAD_PID=$!
# Set up cleanup trap now that we have a PID to kill
trap cleanup SIGINT SIGTERM
cd ..
sleep 5

echo ""
echo "✅ Ready!"
echo ""
echo "🌐 Open: http://localhost:3000"
echo "📁 Sandbox: http://safe.localhost:3000"

echo ""
echo "Press Ctrl+C to stop"

wait $CRYPTPAD_PID
