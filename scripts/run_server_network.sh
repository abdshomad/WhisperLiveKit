#!/bin/bash

# WhisperLiveKit Network Server for H100x2
# Optimized for network access (0.0.0.0) with medium model

# Configuration for network access (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit Network Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server configured for network access."
DEFAULT_HOST="0.0.0.0"
CONFIG_DESCRIPTION="- Model: medium (balanced speed/accuracy)
- Host: 0.0.0.0 (network accessible)
- Diarization: disabled (for faster processing)
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --model large-v3                  # Use large model
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="🌐 NETWORK ACCESSIBLE: Accessible from other machines
   ⚠️  SECURITY NOTE: This server is accessible from the network!
   Make sure your firewall is properly configured."

# Execute the base script with our configuration
exec ./scripts/run_server.sh "$@" 