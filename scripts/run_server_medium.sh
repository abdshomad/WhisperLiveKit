#!/bin/bash

# WhisperLiveKit Medium Model Server for H100x2
# Optimized for medium model (balanced speed/accuracy)

# Configuration for medium model (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit Medium Model Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server with medium model (balanced speed/accuracy)."
CONFIG_DESCRIPTION="- Model: medium (balanced speed/accuracy)
- Diarization: disabled (for faster processing)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --language en                     # Set language to English
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="⚖️  BALANCED: Good speed and accuracy
   Use this for general purpose applications."

# Execute the base script with our configuration
exec ./scripts/run_server.sh "$@" 