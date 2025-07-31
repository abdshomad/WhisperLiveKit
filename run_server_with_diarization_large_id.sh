#!/bin/bash

# WhisperLiveKit Large Model Server for H100x2
# Optimized for large-v3 model with diarization for Indonesian

# Configuration for Indonesian with diarization (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit Large Model Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server with large-v3 model and diarization."
DEFAULT_MODEL="large-v3"
DEFAULT_DIARIZATION="enabled"
CONFIG_DESCRIPTION="- Model: large-v3 (best accuracy, multilingual)
- Diarization: enabled
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --language id                     # Set language to Indonesian
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="🇮🇩 INDONESIAN OPTIMIZED: Best for Indonesian content with speaker identification
   Use this for Indonesian meetings and conversations."

# Execute the base script with our configuration
exec ./run_server.sh "$@"
