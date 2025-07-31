#!/bin/bash

# WhisperLiveKit English-Optimized Server for H100x2
# Optimized for English language processing with medium model

# Configuration for English language (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit English-Optimized Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server optimized for English language processing."
DEFAULT_LANGUAGE="en"
CONFIG_DESCRIPTION="- Model: medium (balanced speed/accuracy)
- Language: English (en)
- Diarization: disabled (for faster processing)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --model large-v3                  # Use large model
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="🇺🇸 ENGLISH OPTIMIZED: Best for English content
   Use this for English-only applications."

# Execute the base script with our configuration
exec ./scripts/run_server.sh "$@" 