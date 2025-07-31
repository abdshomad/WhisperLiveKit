#!/bin/bash

# Activate virtual environment
source .venv/bin/activate

# Set environment variables
export CALLING_SCRIPT="run_server_with_recordings.sh"

# Check GPU status
echo "Checking GPU status..."
nvidia-smi

# Run the server with recordings on port 9002
echo "Starting WhisperLiveKit server with recordings on port 9002..."
python -m whisperlivekit.server_with_recordings --host 0.0.0.0 --port 9002 --model large-v3 --language en --diarization 