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
            echo "📝 Log file: $(ls -t ./logs/*.log 2>/dev/null | head -1 || echo 'No log files found')"
            echo "🌐 Access: http://localhost:9001"
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

# Function to show help
show_help() {
    echo "🚀 $SCRIPT_NAME"
    echo "========================================"
    echo ""
    echo "Usage: $0 [whisperlivekit-server-options]"
    echo ""
    echo "$SCRIPT_DESCRIPTION"
    echo "The server runs in background with PID management and logs to ./logs/YYYYMMDDHHMISS.log"
    echo ""
    
    if [ -n "$CONFIG_DESCRIPTION" ]; then
        echo "Default configuration:"
        echo "$CONFIG_DESCRIPTION"
        echo ""
    fi
    
    echo "Management Commands:"
    echo "  $0 --stop                    # Stop the running server"
    echo "  $0 --restart                 # Restart the server"
    echo "  $0 --status                  # Check server status"
    echo "  $0 --help                    # Show this help"
    echo ""
    
    if [ -n "$USAGE_EXAMPLES" ]; then
        echo "Examples:"
        echo "$USAGE_EXAMPLES"
        echo ""
    fi
    
    if [ -n "$RECOMMENDED_USE" ]; then
        echo "Recommended Use:"
        echo "$RECOMMENDED_USE"
        echo ""
    fi
    
    echo "GPU Configuration:"
    echo "- CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "- CT2_CUDA_DEVICES: $CT2_CUDA_DEVICES"
    echo ""
    echo "Logging:"
    echo "- Logs are written to: ./logs/YYYYMMDDHHMISS.log"
    echo "- PID file: ./server.pid"
    echo ""
    echo "For more information, visit: https://github.com/collabora/WhisperLiveKit"
}

# Configuration variables that can be set by child scripts or passed as parameters
SCRIPT_NAME="${SCRIPT_NAME:-WhisperLiveKit H100x2 Server}"
SCRIPT_DESCRIPTION="${SCRIPT_DESCRIPTION:-This script runs WhisperLiveKit server with H100 GPU optimization.}"

# WhisperLiveKit parameters (following README.md configuration reference)
DEFAULT_MODEL="${DEFAULT_MODEL:-medium}"
DEFAULT_HOST="${DEFAULT_HOST:-localhost}"
DEFAULT_PORT="${DEFAULT_PORT:-9001}"
DEFAULT_LANGUAGE="${DEFAULT_LANGUAGE:-auto}"
DEFAULT_TASK="${DEFAULT_TASK:-transcribe}"
DEFAULT_BACKEND="${DEFAULT_BACKEND:-faster-whisper}"
DEFAULT_DIARIZATION="${DEFAULT_DIARIZATION:-}"
DEFAULT_PUNCTUATION_SPLIT="${DEFAULT_PUNCTUATION_SPLIT:-True}"
DEFAULT_CONFIDENCE_VALIDATION="${DEFAULT_CONFIDENCE_VALIDATION:-False}"
DEFAULT_MIN_CHUNK_SIZE="${DEFAULT_MIN_CHUNK_SIZE:-1.0}"
DEFAULT_VAC="${DEFAULT_VAC:-False}"
DEFAULT_NO_VAD="${DEFAULT_NO_VAD:-False}"
DEFAULT_BUFFER_TRIMMING="${DEFAULT_BUFFER_TRIMMING:-segment}"
DEFAULT_WARMUP_FILE="${DEFAULT_WARMUP_FILE:-jfk.wav}"
DEFAULT_SSL_CERTFILE="${DEFAULT_SSL_CERTFILE:-}"
DEFAULT_SSL_KEYFILE="${DEFAULT_SSL_KEYFILE:-}"
DEFAULT_SEGMENTATION_MODEL="${DEFAULT_SEGMENTATION_MODEL:-pyannote/segmentation-3.0}"
DEFAULT_EMBEDDING_MODEL="${DEFAULT_EMBEDDING_MODEL:-speechbrain/spkrec-ecapa-voxceleb}"

# SimulStreaming-specific parameters
DEFAULT_FRAME_THRESHOLD="${DEFAULT_FRAME_THRESHOLD:-25}"
DEFAULT_BEAMS="${DEFAULT_BEAMS:-1}"
DEFAULT_DECODER="${DEFAULT_DECODER:-auto}"
DEFAULT_AUDIO_MAX_LEN="${DEFAULT_AUDIO_MAX_LEN:-30.0}"
DEFAULT_AUDIO_MIN_LEN="${DEFAULT_AUDIO_MIN_LEN:-0.0}"
DEFAULT_CIF_CKPT_PATH="${DEFAULT_CIF_CKPT_PATH:-}"
DEFAULT_NEVER_FIRE="${DEFAULT_NEVER_FIRE:-False}"
DEFAULT_INIT_PROMPT="${DEFAULT_INIT_PROMPT:-}"
DEFAULT_STATIC_INIT_PROMPT="${DEFAULT_STATIC_INIT_PROMPT:-}"
DEFAULT_MAX_CONTEXT_TOKENS="${DEFAULT_MAX_CONTEXT_TOKENS:-}"
DEFAULT_MODEL_PATH="${DEFAULT_MODEL_PATH:-./base.pt}"

# Script metadata
CONFIG_DESCRIPTION="${CONFIG_DESCRIPTION:-}"
USAGE_EXAMPLES="${USAGE_EXAMPLES:-}"
RECOMMENDED_USE="${RECOMMENDED_USE:-}"
CALLING_SCRIPT="${CALLING_SCRIPT:-$0}"



# Handle management commands first (before parameter parsing)
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
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Parse configuration parameters if provided
while [[ $# -gt 0 ]]; do
    case $1 in
        --config=*)
            CONFIG_FILE="${1#*=}"
            if [ -f "$CONFIG_FILE" ]; then
                source "$CONFIG_FILE"
            fi
            ;;
        # Script metadata parameters
        --script-name=*) SCRIPT_NAME="${1#*=}" ;;
        --script-desc=*) SCRIPT_DESCRIPTION="${1#*=}" ;;
        --config-desc=*) CONFIG_DESCRIPTION="${1#*=}" ;;
        --usage-examples=*) USAGE_EXAMPLES="${1#*=}" ;;
        --recommended-use=*) RECOMMENDED_USE="${1#*=}" ;;
        --calling-script=*) CALLING_SCRIPT="${1#*=}" ;;
        
        # Core WhisperLiveKit parameters
        --model=*) DEFAULT_MODEL="${1#*=}" ;;
        --host=*) DEFAULT_HOST="${1#*=}" ;;
        --port=*) DEFAULT_PORT="${1#*=}" ;;
        --language=*) DEFAULT_LANGUAGE="${1#*=}" ;;
        --task=*) DEFAULT_TASK="${1#*=}" ;;
        --backend=*) DEFAULT_BACKEND="${1#*=}" ;;
        --diarization=*) DEFAULT_DIARIZATION="${1#*=}" ;;
        --punctuation-split=*) DEFAULT_PUNCTUATION_SPLIT="${1#*=}" ;;
        --confidence-validation=*) DEFAULT_CONFIDENCE_VALIDATION="${1#*=}" ;;
        --min-chunk-size=*) DEFAULT_MIN_CHUNK_SIZE="${1#*=}" ;;
        --vac=*) DEFAULT_VAC="${1#*=}" ;;
        --no-vad=*) DEFAULT_NO_VAD="${1#*=}" ;;
        --buffer_trimming=*) DEFAULT_BUFFER_TRIMMING="${1#*=}" ;;
        --warmup-file=*) DEFAULT_WARMUP_FILE="${1#*=}" ;;
        --ssl-certfile=*) DEFAULT_SSL_CERTFILE="${1#*=}" ;;
        --ssl-keyfile=*) DEFAULT_SSL_KEYFILE="${1#*=}" ;;
        --segmentation-model=*) DEFAULT_SEGMENTATION_MODEL="${1#*=}" ;;
        --embedding-model=*) DEFAULT_EMBEDDING_MODEL="${1#*=}" ;;
        
        # SimulStreaming-specific parameters
        --frame-threshold=*) DEFAULT_FRAME_THRESHOLD="${1#*=}" ;;
        --beams=*) DEFAULT_BEAMS="${1#*=}" ;;
        --decoder=*) DEFAULT_DECODER="${1#*=}" ;;
        --audio-max-len=*) DEFAULT_AUDIO_MAX_LEN="${1#*=}" ;;
        --audio-min-len=*) DEFAULT_AUDIO_MIN_LEN="${1#*=}" ;;
        --cif-ckpt-path=*) DEFAULT_CIF_CKPT_PATH="${1#*=}" ;;
        --never-fire=*) DEFAULT_NEVER_FIRE="${1#*=}" ;;
        --init-prompt=*) DEFAULT_INIT_PROMPT="${1#*=}" ;;
        --static-init-prompt=*) DEFAULT_STATIC_INIT_PROMPT="${1#*=}" ;;
        --max-context-tokens=*) DEFAULT_MAX_CONTEXT_TOKENS="${1#*=}" ;;
        --model-path=*) DEFAULT_MODEL_PATH="${1#*=}" ;;
        
        *) break ;;
    esac
    shift
done

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
            echo "📝 Log file: $(ls -t ./logs/*.log 2>/dev/null | head -1 || echo 'No log files found')"
            echo "🌐 Access: http://localhost:9001"
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

# Function to show help
show_help() {
    echo "🚀 $SCRIPT_NAME"
    echo "========================================"
    echo ""
    echo "Usage: $0 [whisperlivekit-server-options]"
    echo ""
    echo "$SCRIPT_DESCRIPTION"
    echo "The server runs in background with PID management and logs to ./logs/YYYYMMDDHHMISS.log"
    echo ""
    
    if [ -n "$CONFIG_DESCRIPTION" ]; then
        echo "Default configuration:"
        echo "$CONFIG_DESCRIPTION"
        echo ""
    fi
    
    echo "Management Commands:"
    echo "  $0 --stop                    # Stop the running server"
    echo "  $0 --restart                 # Restart the server"
    echo "  $0 --status                  # Check server status"
    echo "  $0 --help                    # Show this help"
    echo ""
    
    if [ -n "$USAGE_EXAMPLES" ]; then
        echo "Examples:"
        echo "$USAGE_EXAMPLES"
        echo ""
    fi
    
    if [ -n "$RECOMMENDED_USE" ]; then
        echo "Recommended Use:"
        echo "$RECOMMENDED_USE"
        echo ""
    fi
    
    echo "GPU Configuration:"
    echo "- CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "- CT2_CUDA_DEVICES: $CT2_CUDA_DEVICES"
    echo ""
    echo "Logging:"
    echo "- Log file: $LOG_FILE"
    echo "- PID file: $PID_FILE"
    echo "- Background execution with PID management"
    echo ""
    echo "To view logs: tail -f ./logs/YYYYMMDDHHMISS.log"
    echo ""
    
    # Show whisperlivekit-server help if available
    if command -v whisperlivekit-server >/dev/null 2>&1; then
        whisperlivekit-server --help
    else
        echo "Note: whisperlivekit-server command not found. Make sure the virtual environment is activated."
    fi
}



# Activate virtual environment
source .venv/bin/activate

# Set environment variables for H100 GPU acceleration
export CUDA_VISIBLE_DEVICES="0,1"
export CT2_CUDA_DEVICES="0,1"

# Enhanced library path for H100 compatibility
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-12.1/targets/x86_64-linux/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_cupti/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_nvrtc/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_runtime/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cufft/lib:/usr/local/lib/python3.10/dist-packages/nvidia/curand/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusolver/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusparse/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nccl/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nvtx/lib:$LD_LIBRARY_PATH"

# Check if server is already running
if check_server_running; then
    exit 0
fi

# Build default arguments if no arguments provided
if [ $# -eq 0 ]; then
    DEFAULT_ARGS="--model $DEFAULT_MODEL --host $DEFAULT_HOST --port $DEFAULT_PORT --language $DEFAULT_LANGUAGE --task $DEFAULT_TASK --backend $DEFAULT_BACKEND"
    
    # Add optional parameters if they differ from defaults
    if [ -n "$DEFAULT_DIARIZATION" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --diarization"
    fi
    
    if [ "$DEFAULT_PUNCTUATION_SPLIT" != "True" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --punctuation-split $DEFAULT_PUNCTUATION_SPLIT"
    fi
    
    if [ "$DEFAULT_CONFIDENCE_VALIDATION" = "True" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --confidence-validation"
    fi
    
    if [ "$DEFAULT_MIN_CHUNK_SIZE" != "1.0" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --min-chunk-size $DEFAULT_MIN_CHUNK_SIZE"
    fi
    
    if [ "$DEFAULT_VAC" = "True" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --vac"
    fi
    
    if [ "$DEFAULT_NO_VAD" = "True" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --no-vad"
    fi
    
    if [ "$DEFAULT_BUFFER_TRIMMING" != "segment" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --buffer_trimming $DEFAULT_BUFFER_TRIMMING"
    fi
    
    if [ -n "$DEFAULT_WARMUP_FILE" ] && [ "$DEFAULT_WARMUP_FILE" != "jfk.wav" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --warmup-file $DEFAULT_WARMUP_FILE"
    fi
    
    if [ -n "$DEFAULT_SSL_CERTFILE" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --ssl-certfile $DEFAULT_SSL_CERTFILE"
    fi
    
    if [ -n "$DEFAULT_SSL_KEYFILE" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --ssl-keyfile $DEFAULT_SSL_KEYFILE"
    fi
    
    if [ -n "$DEFAULT_SEGMENTATION_MODEL" ] && [ "$DEFAULT_SEGMENTATION_MODEL" != "pyannote/segmentation-3.0" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --segmentation-model $DEFAULT_SEGMENTATION_MODEL"
    fi
    
    if [ -n "$DEFAULT_EMBEDDING_MODEL" ] && [ "$DEFAULT_EMBEDDING_MODEL" != "speechbrain/spkrec-ecapa-voxceleb" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --embedding-model $DEFAULT_EMBEDDING_MODEL"
    fi
    
    # SimulStreaming-specific parameters
    if [ "$DEFAULT_FRAME_THRESHOLD" != "25" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --frame-threshold $DEFAULT_FRAME_THRESHOLD"
    fi
    
    if [ "$DEFAULT_BEAMS" != "1" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --beams $DEFAULT_BEAMS"
    fi
    
    if [ -n "$DEFAULT_DECODER" ] && [ "$DEFAULT_DECODER" != "auto" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --decoder $DEFAULT_DECODER"
    fi
    
    if [ "$DEFAULT_AUDIO_MAX_LEN" != "30.0" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --audio-max-len $DEFAULT_AUDIO_MAX_LEN"
    fi
    
    if [ "$DEFAULT_AUDIO_MIN_LEN" != "0.0" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --audio-min-len $DEFAULT_AUDIO_MIN_LEN"
    fi
    
    if [ -n "$DEFAULT_CIF_CKPT_PATH" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --cif-ckpt-path $DEFAULT_CIF_CKPT_PATH"
    fi
    
    if [ "$DEFAULT_NEVER_FIRE" = "True" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --never-fire"
    fi
    
    if [ -n "$DEFAULT_INIT_PROMPT" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --init-prompt $DEFAULT_INIT_PROMPT"
    fi
    
    if [ -n "$DEFAULT_STATIC_INIT_PROMPT" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --static-init-prompt $DEFAULT_STATIC_INIT_PROMPT"
    fi
    
    if [ -n "$DEFAULT_MAX_CONTEXT_TOKENS" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --max-context-tokens $DEFAULT_MAX_CONTEXT_TOKENS"
    fi
    
    if [ -n "$DEFAULT_MODEL_PATH" ] && [ "$DEFAULT_MODEL_PATH" != "./base.pt" ]; then
        DEFAULT_ARGS="$DEFAULT_ARGS --model-path $DEFAULT_MODEL_PATH"
    fi
    
    echo "🚀 Starting $SCRIPT_NAME in background"
    echo "====================================================================="
    echo "Core Configuration:"
    echo "- Model: $DEFAULT_MODEL"
    echo "- Host: $DEFAULT_HOST"
    echo "- Port: $DEFAULT_PORT"
    echo "- Language: $DEFAULT_LANGUAGE"
    echo "- Task: $DEFAULT_TASK"
    echo "- Backend: $DEFAULT_BACKEND"
    if [ -n "$DEFAULT_DIARIZATION" ]; then
        echo "- Diarization: enabled"
    else
        echo "- Diarization: disabled"
    fi
    
    echo ""
    echo "Advanced Configuration:"
    echo "- Punctuation Split: $DEFAULT_PUNCTUATION_SPLIT"
    echo "- Confidence Validation: $DEFAULT_CONFIDENCE_VALIDATION"
    echo "- Min Chunk Size: $DEFAULT_MIN_CHUNK_SIZE"
    echo "- VAC: $DEFAULT_VAC"
    echo "- No VAD: $DEFAULT_NO_VAD"
    echo "- Buffer Trimming: $DEFAULT_BUFFER_TRIMMING"
    
    if [ -n "$DEFAULT_SSL_CERTFILE" ] || [ -n "$DEFAULT_SSL_KEYFILE" ]; then
        echo ""
        echo "SSL Configuration:"
        if [ -n "$DEFAULT_SSL_CERTFILE" ]; then
            echo "- SSL Cert: $DEFAULT_SSL_CERTFILE"
        fi
        if [ -n "$DEFAULT_SSL_KEYFILE" ]; then
            echo "- SSL Key: $DEFAULT_SSL_KEYFILE"
        fi
    fi
    
    if [ "$DEFAULT_BACKEND" = "simulstreaming" ]; then
        echo ""
        echo "SimulStreaming Configuration:"
        echo "- Frame Threshold: $DEFAULT_FRAME_THRESHOLD"
        echo "- Beams: $DEFAULT_BEAMS"
        echo "- Decoder: $DEFAULT_DECODER"
        echo "- Audio Max Len: $DEFAULT_AUDIO_MAX_LEN"
        echo "- Audio Min Len: $DEFAULT_AUDIO_MIN_LEN"
    fi
    
    echo ""
    echo "Access the interface at: http://$DEFAULT_HOST:$DEFAULT_PORT"
    echo "Log file: $LOG_FILE"
    echo "PID file: $PID_FILE"
    echo ""
    echo "GPU Configuration:"
    echo "- CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "- CT2_CUDA_DEVICES: $CT2_CUDA_DEVICES"
    echo ""
    
    # Start with default parameters in background
    # Add script identification to log
    echo "=== SCRIPT: $CALLING_SCRIPT ===" >> "$LOG_FILE"
    echo "=== TIMESTAMP: $(date) ===" >> "$LOG_FILE"
    echo "=== CONFIG: Model=$DEFAULT_MODEL, Host=$DEFAULT_HOST, Port=$DEFAULT_PORT, Language=$DEFAULT_LANGUAGE, Task=$DEFAULT_TASK, Backend=$DEFAULT_BACKEND, Diarization=$DEFAULT_DIARIZATION ===" >> "$LOG_FILE"
    echo "=== GPU: CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES, CT2_CUDA_DEVICES=$CT2_CUDA_DEVICES ===" >> "$LOG_FILE"
    echo "=== ARGS: $DEFAULT_ARGS ===" >> "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
    
    CALLING_SCRIPT="$CALLING_SCRIPT" whisperlivekit-server $DEFAULT_ARGS >> "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > "$PID_FILE"
    
    echo "✅ Server started with PID: $SERVER_PID"
    echo "📝 Logs are being written to: $LOG_FILE"
    echo "🆔 PID saved to: $PID_FILE"
    echo "🌐 Access the interface at: http://$DEFAULT_HOST:$DEFAULT_PORT"
    echo ""
    echo "Management commands:"
    echo "  $0 --stop      # Stop server"
    echo "  $0 --restart   # Restart server"
    echo "  $0 --status    # Check status"
    echo "  tail -f $LOG_FILE          # Monitor logs"
else
    echo "🚀 Starting $SCRIPT_NAME in background"
    echo "====================================================="
    echo "GPU Configuration:"
    echo "- CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
    echo "- CT2_CUDA_DEVICES: $CT2_CUDA_DEVICES"
    echo "Log file: $LOG_FILE"
    echo "PID file: $PID_FILE"
    echo ""
    
    # Filter out management commands from arguments passed to whisperlivekit-server
    SERVER_ARGS=()
    for arg in "$@"; do
        case "$arg" in
            --stop|--restart|--status|--help|-h)
                # Skip management commands
                ;;
            *)
                # Add non-management arguments to server args
                SERVER_ARGS+=("$arg")
                ;;
        esac
    done
    
    echo "Arguments: ${SERVER_ARGS[*]}"
    echo ""
    
    # Add script identification to log
    echo "=== SCRIPT: $CALLING_SCRIPT ===" >> "$LOG_FILE"
    echo "=== TIMESTAMP: $(date) ===" >> "$LOG_FILE"
    echo "=== CONFIG: Model=$DEFAULT_MODEL, Host=$DEFAULT_HOST, Port=$DEFAULT_PORT, Language=$DEFAULT_LANGUAGE, Task=$DEFAULT_TASK, Backend=$DEFAULT_BACKEND, Diarization=$DEFAULT_DIARIZATION ===" >> "$LOG_FILE"
    echo "=== GPU: CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES, CT2_CUDA_DEVICES=$CT2_CUDA_DEVICES ===" >> "$LOG_FILE"
    echo "=== ARGS: ${SERVER_ARGS[*]} ===" >> "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
    
    CALLING_SCRIPT="$CALLING_SCRIPT" whisperlivekit-server "${SERVER_ARGS[@]}" >> "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > "$PID_FILE"
    
    echo "✅ Server started with PID: $SERVER_PID"
    echo "📝 Logs are being written to: $LOG_FILE"
    echo "🆔 PID saved to: $PID_FILE"
    echo ""
    echo "Management commands:"
    echo "  $0 --stop      # Stop server"
    echo "  $0 --restart   # Restart server"
    echo "  $0 --status    # Check status"
    echo "  tail -f $LOG_FILE          # Monitor logs"
fi
