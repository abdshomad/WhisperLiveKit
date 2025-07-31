#!/bin/bash

# WhisperLiveKit Accurate Server for H100x2
# Optimized for maximum accuracy with large model and diarization

# Configuration for maximum accuracy (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit Accurate Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server optimized for maximum accuracy."
DEFAULT_MODEL="large-v3"
DEFAULT_DIARIZATION="enabled"
CONFIG_DESCRIPTION="- Model: large-v3 (highest accuracy, multilingual)
- Diarization: enabled (speaker identification)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --language en                     # Set language to English
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="🎯 ACCURACY OPTIMIZED: Highest accuracy with speaker identification
   Use this for applications where accuracy is critical."

# Execute the base script with our configuration
exec ./scripts/run_server.sh "$@" 