#!/bin/bash

# WhisperLiveKit H100x2 Server Runner
# Enhanced for H100 GPU optimization with PID-based background execution and logging

# Create logs directory if it doesn't exist
mkdir -p ./logs

# Generate timestamp for log file
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
LOG_FILE="./logs/${TIMESTAMP}.log"
PID_FILE="./server.pid"

# Function to check if server is already running
check_server_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "⚠️  Server is already running with PID: $PID"
            echo "📝 Log file: $(ls -t ./logs/*.log | head -1)"
            echo "🌐 Access: http://localhost:9001"
            echo ""
            echo "To stop: ./run_server.sh --stop"
            echo "To restart: ./run_server.sh --restart"
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
            echo "🛑 Stopping server with PID: $PID"
            kill "$PID"
            rm -f "$PID_FILE"
            echo "✅ Server stopped"
        else
            echo "⚠️  Server not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "⚠️  No PID file found. Server may not be running."
        echo "💡 You can also stop with: pkill -f 'whisperlivekit-server'"
    fi
}

# Function to restart server
restart_server() {
    echo "🔄 Restarting server..."
    stop_server
    sleep 2
    # Continue with normal startup
}

# Handle stop and restart commands
if [[ "$1" == "--stop" ]]; then
    stop_server
    exit 0
elif [[ "$1" == "--restart" ]]; then
    restart_server
elif [[ "$1" == "--status" ]]; then
    if check_server_running; then
        exit 0
    else
        echo "❌ Server is not running"
        exit 1
    fi
fi

# Activate virtual environment
source .venv/bin/activate

# Set environment variables for H100 GPU acceleration
export CUDA_VISIBLE_DEVICES="0,1"
export CT2_CUDA_DEVICES="0,1"

# Enhanced library path for H100 compatibility
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-12.1/targets/x86_64-linux/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_cupti/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_nvrtc/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_runtime/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cufft/lib:/usr/local/lib/python3.10/dist-packages/nvidia/curand/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusolver/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusparse/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nccl/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nvtx/lib:$LD_LIBRARY_PATH"

# Check if help is requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "🚀 WhisperLiveKit H100x2 Server Runner"
    echo "========================================"
    echo ""
    echo "Usage: $0 [whisperlivekit-server-options]"
    echo ""
    echo "This script runs WhisperLiveKit server with H100 GPU optimization."
    echo "All arguments are passed directly to whisperlivekit-server."
    echo "The server runs in background with PID management and logs to ./logs/YYYYMMDDHHMISS.log"
    echo ""
    echo "Management Commands:"
    echo "  $0 --stop                    # Stop the running server"
    echo "  $0 --restart                 # Restart the server"
    echo "  $0 --status                  # Check server status"
    echo "  $0 --help                    # Show this help"
    echo ""
    echo "GPU Configuration:"
    echo "- CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "- CT2_CUDA_DEVICES: $CT2_CUDA_DEVICES"
    echo ""
    echo "Logging:"
    echo "- Log file: $LOG_FILE"
    echo "- PID file: $PID_FILE"
    echo "- Background execution with PID management"
    echo ""
    echo "Examples:"
    echo "  $0 --model medium --host 0.0.0.0 --port 9001"
    echo "  $0 --model large --diarization"
    echo "  $0 --stop"
    echo "  $0 --restart"
    echo "  $0 --help"
    echo ""
    
    # Show whisperlivekit-server help
    whisperlivekit-server --help
    exit 0
fi

# Check if server is already running
if check_server_running; then
    exit 0
fi

# Default parameters optimized for H100 (if no arguments provided)
if [ $# -eq 0 ]; then
    MODEL="medium"
    HOST="localhost"
    PORT="9001"
    DIARIZATION=""
    
    echo "🚀 Starting WhisperLiveKit H100x2 Server (default mode) in background"
    echo "====================================================================="
    echo "Model: $MODEL"
    echo "Host: $HOST"
    echo "Port: $PORT"
    echo "Diarization: ${DIARIZATION:-disabled}"
    echo "Access the interface at: http://$HOST:$PORT"
    echo "Log file: $LOG_FILE"
    echo "PID file: $PID_FILE"
    echo ""
    echo "GPU Configuration:"
    echo "- CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "- CT2_CUDA_DEVICES: $CT2_CUDA_DEVICES"
    echo ""
    
    # Start with default parameters in background
    whisperlivekit-server --model $MODEL --host $HOST --port $PORT > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > "$PID_FILE"
    
    echo "✅ Server started with PID: $SERVER_PID"
    echo "📝 Logs are being written to: $LOG_FILE"
    echo "🆔 PID saved to: $PID_FILE"
    echo "🌐 Access the interface at: http://$HOST:$PORT"
    echo ""
    echo "Management commands:"
    echo "  ./run_server.sh --stop      # Stop server"
    echo "  ./run_server.sh --restart   # Restart server"
    echo "  ./run_server.sh --status    # Check status"
    echo "  tail -f $LOG_FILE          # Monitor logs"
else
    echo "🚀 Starting WhisperLiveKit H100x2 Server in background"
    echo "====================================================="
    echo "GPU Configuration:"
    echo "- CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "- CT2_CUDA_DEVICES: $CT2_CUDA_DEVICES"
    echo "Log file: $LOG_FILE"
    echo "PID file: $PID_FILE"
    echo ""
    echo "Arguments: $@"
    echo ""
    
    # Pass all arguments to whisperlivekit-server in background
    whisperlivekit-server "$@" > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > "$PID_FILE"
    
    echo "✅ Server started with PID: $SERVER_PID"
    echo "📝 Logs are being written to: $LOG_FILE"
    echo "🆔 PID saved to: $PID_FILE"
    echo ""
    echo "Management commands:"
    echo "  ./run_server.sh --stop      # Stop server"
    echo "  ./run_server.sh --restart   # Restart server"
    echo "  ./run_server.sh --status    # Check status"
    echo "  tail -f $LOG_FILE          # Monitor logs"
fi
