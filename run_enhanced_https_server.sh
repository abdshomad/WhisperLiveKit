#!/bin/bash

# Enhanced WhisperLiveKit HTTPS Server Runner
# This script runs the enhanced server with SSL support for HTTPS/WSS

echo "🔒 Starting Enhanced WhisperLiveKit HTTPS Server"
echo "================================================"

# Activate virtual environment
source .venv/bin/activate

# Set environment variables
export CALLING_SCRIPT="run_enhanced_https_server.sh"
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Fix CUDA library path for GPU support
export LD_LIBRARY_PATH="/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH"

# Check GPU status
echo "🔍 Checking GPU status..."
nvidia-smi

# Check if SSL certificates exist
if [ ! -f "ssl/cert.pem" ] || [ ! -f "ssl/key.pem" ]; then
    echo "⚠️  SSL certificates not found. Generating self-signed certificates..."
    mkdir -p ssl
    openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=poc-sketsa-ak-9002.demoin.id"
    echo "✅ SSL certificates generated"
fi

# Check if port 9002 is available
if lsof -Pi :9002 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 9002 is already in use. Stopping existing process..."
    pkill -f "server_with_recordings_enhanced"
    sleep 2
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Start the enhanced HTTPS server
echo "🚀 Starting enhanced HTTPS server on port 9002..."
echo "📊 Enhanced logging enabled"
echo "📋 Version information will be displayed in footer"
echo "🔧 Debug console available in web interface"
echo "🎯 GPU acceleration enabled with H100 support"
echo "🔒 SSL/HTTPS enabled with secure WebSocket (WSS)"

python -m whisperlivekit.server_with_recordings_enhanced_https \
    --host 0.0.0.0 \
    --port 9002 \
    --model tiny \
    --language en \
    --backend faster-whisper

echo "✅ Enhanced HTTPS server stopped" 