#!/bin/bash

# WhisperLiveKit Large Model Server for H100x2
# Optimized for large model (highest accuracy, no diarization)

# Configuration for large model (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit Large Model Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server with large model (highest accuracy)."
DEFAULT_MODEL="large-v3"
CONFIG_DESCRIPTION="- Model: large-v3 (highest accuracy, multilingual)
- Diarization: disabled (for faster processing)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --language en                     # Set language to English
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="🎯 HIGH ACCURACY: Best transcription quality
   Use this when accuracy is more important than speed."

# Execute the base script with our configuration
exec ./scripts/run_server.sh "$@" 