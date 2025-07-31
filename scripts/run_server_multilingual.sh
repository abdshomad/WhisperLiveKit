#!/bin/bash

# WhisperLiveKit Multilingual Server for H100x2
# Optimized for multilingual processing with large model and diarization

# Configuration for multilingual with diarization (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit Multilingual Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server optimized for multilingual processing."
DEFAULT_MODEL="large-v3"
DEFAULT_DIARIZATION="enabled"
CONFIG_DESCRIPTION="- Model: large-v3 (highest accuracy, multilingual)
- Diarization: enabled (speaker identification)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --language es                     # Set language to Spanish
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="🌍 MULTILINGUAL: Supports multiple languages with speaker identification
   Use this for meetings with multiple speakers in different languages."

# Execute the base script with our configuration
exec ./scripts/run_server.sh "$@" 