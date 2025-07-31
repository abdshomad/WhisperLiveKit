#!/bin/bash

# WhisperLiveKit Indonesian
# Speaker identification focused for Bahasa Indonesia

# Configuration - easily changeable
SCRIPT_NAME="WhisperLiveKit Indonesian Very Accurate Server (H100x2)"
SCRIPT_DESC="This script runs WhisperLiveKit server optimized for Speaker identification focused for Bahasa Indonesia."
MODEL="large-v3"
LANGUAGE="id"
DIARIZATION="enabled"
CONFIG_DESC="- Model: large-v3 (highest accuracy, slower processing)
- Language: Indonesian (id)
- Diarization: enabled (speaker identification)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --model large-v3                  # Use large model
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="🇮🇩 INDONESIAN Very Accurate: Speaker identification focused for Bahasa Indonesia
     Use this for Indonesian applications."

exec ./run_server.sh \
    --calling-script="$0" \
    --script-name="$SCRIPT_NAME" \
    --script-desc="$SCRIPT_DESC" \
    --model="$MODEL" \
    --language="$LANGUAGE" \
    --diarization="$DIARIZATION" \
    --config-desc="$CONFIG_DESC" \
    --usage-examples="$USAGE_EXAMPLES" \
    --recommended-use="$RECOMMENDED_USE" \
    --best_of 5 --beam_size 5 --temperature 0.0 \
    "$@"
