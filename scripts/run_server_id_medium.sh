#!/bin/bash

# WhisperLiveKit Indonesian
# Balanced approach with medium model for Bahasa Indonesia

# Configuration - easily changeable
SCRIPT_NAME="WhisperLiveKit Indonesian Medium Server (H100x2)"
SCRIPT_DESC="This script runs WhisperLiveKit server optimized for Balanced approach with medium model for Bahasa Indonesia."
MODEL="medium"
LANGUAGE="id"
DIARIZATION="enabled"
CONFIG_DESC="- Model: medium (balanced speed/accuracy)
- Language: Indonesian (id)
- Diarization: enabled (speaker identification)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --model large-v3                  # Use large model
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="🇮🇩 INDONESIAN Medium: Balanced approach with medium model for Bahasa Indonesia
     Use this for Indonesian applications."

exec ./scripts/run_server.sh \
    --calling-script="$0" \
    --script-name="$SCRIPT_NAME" \
    --script-desc="$SCRIPT_DESC" \
    --model="$MODEL" \
    --language="$LANGUAGE" \
    --diarization="$DIARIZATION" \
    --config-desc="$CONFIG_DESC" \
    --usage-examples="$USAGE_EXAMPLES" \
    --recommended-use="$RECOMMENDED_USE" \
    "$@"
