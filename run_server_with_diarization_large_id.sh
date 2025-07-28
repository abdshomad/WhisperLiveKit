#!/bin/bash

# WhisperLiveKit Large Model Server for H100x2
# Optimized for large-v3 model with diarization
# Uses the improved run_server.sh script with PID-based background execution

# Check if help is requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "🚀 WhisperLiveKit Large Model Server (H100x2)"
    echo "=============================================="
    echo ""
    echo "Usage: $0 [whisperlivekit-server-options]"
    echo ""
    echo "This script runs WhisperLiveKit server with large-v3 model and diarization."
    echo "It uses the improved run_server.sh script with optimized H100 GPU settings."
    echo "The server runs in background with PID management and logs to ./logs/YYYYMMDDHHMISS.log"
    echo ""
    echo "Default configuration:"
    echo "- Model: large-v3 (best accuracy, multilingual)"
    echo "- Diarization: enabled"
    echo "- Host: localhost"
    echo "- Port: 9001"
    echo "- Language: auto (automatic detection)"
    echo "- Background execution with PID management"
    echo ""
    echo "Management Commands:"
    echo "  $0 --stop                    # Stop the running server"
    echo "  $0 --restart                 # Restart the server"
    echo "  $0 --status                  # Check server status"
    echo "  $0 --help                    # Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use default settings"
    echo "  $0 --port 9002                       # Change port"
    echo "  $0 --language id                     # Set language to Indonesian"
    echo "  $0 --stop                           # Stop server"
    echo "  $0 --restart                        # Restart server"
    echo "  $0 --help                           # Show this help"
    echo ""
    echo "To view logs: tail -f ./logs/YYYYMMDDHHMISS.log"
    echo ""
    exit 0
fi

# Handle management commands by passing them to run_server.sh
if [[ "$1" == "--stop" || "$1" == "--restart" || "$1" == "--status" ]]; then
    exec ./run_server.sh "$@"
fi

echo "🚀 Starting WhisperLiveKit Large Model Server (H100x2) in background"
echo "===================================================================="
echo "Model: large-v3 (best accuracy, multilingual)"
echo "Diarization: enabled"
echo "Host: localhost"
echo "Port: 9001"
echo "Access the interface at: http://localhost:9001"
echo "Background execution with PID management enabled"
echo ""
echo "Using run_server.sh with large-v3 model and diarization"
echo ""

# Use the improved run_server.sh script with large model and diarization
# The script will handle background execution and logging automatically
exec ./run_server.sh --model large-v3 --host localhost --port 9001 --diarization --language auto "$@"
