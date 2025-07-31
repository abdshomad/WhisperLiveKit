#!/bin/bash

# Enhanced WhisperLiveKit Server Runner
# This script runs the enhanced server with comprehensive logging and version information

echo "🎤 Starting Enhanced WhisperLiveKit Server"
echo "=========================================="

# Activate virtual environment
source .venv/bin/activate

# Set environment variables
export CALLING_SCRIPT="run_enhanced_server.sh"
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Fix CUDA library path for GPU support
export LD_LIBRARY_PATH="/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH"

# Check GPU status
echo "🔍 Checking GPU status..."
nvidia-smi

# Check if port 9002 is available
if lsof -Pi :9002 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 9002 is already in use. Stopping existing process..."
    pkill -f "server_with_recordings_enhanced"
    sleep 2
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Start the enhanced server
echo "🚀 Starting enhanced server on port 9002..."
echo "📊 Enhanced logging enabled"
echo "📋 Version information will be displayed in footer"
echo "🔧 Debug console available in web interface"
echo "🎯 GPU acceleration enabled with H100 support"

python -m whisperlivekit.server_with_recordings_enhanced \
    --host 0.0.0.0 \
    --port 9002 \
    --model tiny \
    --language en \
    --backend faster-whisper

echo "✅ Enhanced server stopped" 