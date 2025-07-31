#!/bin/bash

# WhisperLiveKit FastAPI Server Runner
# Enhanced for H100 GPU optimization with PID-based background execution and logging

# Create logs directory if it doesn't exist
mkdir -p ./logs

# Generate timestamp for log file
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
LOG_FILE="./logs/fastapi_${TIMESTAMP}.log"
PID_FILE="./fastapi_server.pid"

# Set environment variable for Python application to use the same log file
export WHISPERLIVEKIT_LOG_FILE="$LOG_FILE"

# Function to check if server is already running
check_server_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "⚠️  FastAPI server is already running with PID: $PID"
            echo "📝 Log file: $(ls -t ./logs/fastapi_*.log 2>/dev/null | head -1 || echo 'No log files found')"
            echo "🌐 Access: http://localhost:${PORT:-9002}"
            echo "📚 API Docs: http://localhost:${PORT:-9002}/docs"
            echo ""
            echo "To stop: $0 --stop"
            echo "To restart: $0 --restart"
            return 0
        else
            echo "🧹 Cleaning up stale PID file..."
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

# Function to stop server
stop_server() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "🛑 Stopping FastAPI server with PID: $PID"
            kill "$PID"
            rm -f "$PID_FILE"
            echo "✅ FastAPI server stopped"
        else
            echo "⚠️  Server not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "⚠️  No PID file found. Server may not be running."
        echo "💡 You can also stop with: pkill -f 'python main.py'"
    fi
}

# Function to restart server
restart_server() {
    echo "🔄 Restarting FastAPI server..."
    stop_server
    sleep 2
    # Continue with normal startup
}

# Function to show help
show_help() {
    echo "🚀 WhisperLiveKit FastAPI Server"
    echo "========================================"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "A modern FastAPI-based web interface for WhisperLiveKit with:"
    echo "- Real-time speech recognition via WebSocket"
    echo "- Modern responsive UI with Tailwind CSS"
    echo "- Jinja2 templates for dynamic content"
    echo "- GPU-accelerated processing"
    echo "- Automatic API documentation"
    echo ""
    echo "Management Commands:"
    echo "  $0 --stop                    # Stop the running server"
    echo "  $0 --restart                 # Restart the server"
    echo "  $0 --status                  # Check server status"
    echo "  $0 --help                    # Show this help"
    echo ""
    echo "Access URLs:"
echo "- Web Interface: http://localhost:${PORT:-8000}"
echo "- API Documentation: http://localhost:${PORT:-8000}/docs"
echo "- Health Check: http://localhost:${PORT:-8000}/api/health"
echo ""
    echo "GPU Configuration:"
    echo "- CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES:-'all'}"
    echo "- CT2_CUDA_DEVICES: ${CT2_CUDA_DEVICES:-'all'}"
    echo ""
}

# Function to check GPU status
check_gpu() {
    echo "🔍 Checking GPU status..."
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=name,memory.total,memory.free,memory.used --format=csv,noheader,nounits
        echo ""
    else
        echo "⚠️  nvidia-smi not found. GPU may not be available."
    fi
}

# Function to show status
show_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ FastAPI server is running with PID: $PID"
            echo "🌐 Web Interface: http://localhost:${PORT:-8000}"
            echo "📚 API Docs: http://localhost:${PORT:-8000}/docs"
            echo "📝 Log file: $(ls -t ./logs/fastapi_*.log 2>/dev/null | head -1 || echo 'No log files found')"
        else
            echo "❌ Server PID exists but process not running"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ Server not running"
    fi
}

# Load environment variables from .env file if it exists (but don't override existing env vars)
if [ -f ".env" ]; then
    # Only set variables that aren't already set
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
            var_name=$(echo "$line" | cut -d'=' -f1)
            if [[ -z "${!var_name}" ]]; then
                export "$line"
            fi
        fi
    done < .env
fi

# Set default environment variables
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-"0"}
export CT2_CUDA_DEVICES=${CT2_CUDA_DEVICES:-"0"}
export PORT=${PORT:-"9002"}
export HOST=${HOST:-"0.0.0.0"}

# Enhanced library path for H100 compatibility (from run_server.sh)
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-12.1/targets/x86_64-linux/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_cupti/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_nvrtc/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_runtime/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cufft/lib:/usr/local/lib/python3.10/dist-packages/nvidia/curand/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusolver/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusparse/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nccl/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nvtx/lib:$LD_LIBRARY_PATH"

# Set environment variable for Python application to use the same log file
export WHISPERLIVEKIT_LOG_FILE="$LOG_FILE"

# Parse command line arguments
case "${1:-}" in
    --stop)
        stop_server
        exit 0
        ;;
    --restart)
        restart_server
        ;;
    --status)
        show_status
        exit 0
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
esac

# Check if server is already running
if check_server_running; then
    exit 0
fi

# Check GPU before starting
check_gpu

echo "🚀 Starting WhisperLiveKit FastAPI server in background"
echo "====================================================================="
echo "Configuration:"
echo "- Host: $HOST"
echo "- Port: $PORT"
echo "- GPU: CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
echo "- GPU: CT2_CUDA_DEVICES=$CT2_CUDA_DEVICES"
echo "- Log file: $LOG_FILE"
echo "- PID file: $PID_FILE"
echo ""
echo "Access URLs:"
echo "- Web Interface: http://localhost:$PORT"
echo "- API Documentation: http://localhost:$PORT/docs"
echo "- Health Check: http://localhost:$PORT/api/health"
echo ""

# Add script identification to log
echo "=== FASTAPI SERVER START ===" >> "$LOG_FILE"
echo "=== TIMESTAMP: $(date) ===" >> "$LOG_FILE"
echo "=== GPU: CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES, CT2_CUDA_DEVICES=$CT2_CUDA_DEVICES ===" >> "$LOG_FILE"
echo "==========================================" >> "$LOG_FILE"

# Start the FastAPI server using virtual environment
source .venv/bin/activate && uv run python main.py --host "$HOST" --port "$PORT" >> "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > "$PID_FILE"

echo "✅ FastAPI server started with PID: $SERVER_PID"
echo "📝 Logs are being written to: $LOG_FILE"
echo "🆔 PID saved to: $PID_FILE"
echo ""
echo "Management commands:"
echo "  $0 --stop      # Stop server"
echo "  $0 --restart   # Restart server"
echo "  $0 --status    # Check status"
echo "  tail -f $LOG_FILE          # Monitor logs"
echo ""
echo "🌐 Access the interface at: http://localhost:$PORT"
echo "📚 API documentation at: http://localhost:$PORT/docs" 