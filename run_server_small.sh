#!/bin/bash

# WhisperLiveKit Small Model Server for H100x2
# Optimized for small model (fastest processing, lower accuracy)

# Configuration for small model (only set what differs from defaults)
export SCRIPT_NAME="WhisperLiveKit Small Model Server (H100x2)"
export SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server with small model (fastest processing)."
export DEFAULT_MODEL="small"
export CONFIG_DESCRIPTION="- Model: small (fastest processing, lower accuracy)
- Diarization: disabled (for maximum speed)
- Background execution with PID management"
export USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --language en                     # Set language to English
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
export RECOMMENDED_USE="⚡ SPEED OPTIMIZED: Fastest processing with lower accuracy
   Use this for real-time applications where speed is critical."

# Execute the base script with our configuration
exec ./run_server.sh "$@" 