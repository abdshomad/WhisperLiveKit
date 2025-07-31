#!/bin/bash

# WhisperLiveKit Fast Server for H100x2
# Optimized for maximum speed with small model

# Configuration for maximum speed (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit Fast Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server optimized for maximum speed."
DEFAULT_MODEL="small"
CONFIG_DESCRIPTION="- Model: small (fastest processing, lower accuracy)
- Diarization: disabled (for maximum speed)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --language en                     # Set language to English
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="⚡ SPEED OPTIMIZED: Fastest processing with lower accuracy
   Use this for real-time applications where speed is critical."

# Execute the base script with our configuration
exec ./run_server.sh "$@" 