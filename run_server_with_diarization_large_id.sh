#!/bin/bash

# WhisperLiveKit Server Runner with Diarization and Large Model for Bahasa Indonesia
# This script activates the virtual environment and starts the WhisperLiveKit server
# with speaker diarization, large model, and Indonesian language support

# Activate virtual environment
source .venv/bin/activate

# Set environment variables for GPU acceleration
export CUDA_VISIBLE_DEVICES="0,1"
export CT2_CUDA_DEVICES="0,1"

# Set comprehensive library paths for CUDA 12.1 compatibility
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-12.1/targets/x86_64-linux/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_cupti/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_nvrtc/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_runtime/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cufft/lib:/usr/local/lib/python3.10/dist-packages/nvidia/curand/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusolver/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusparse/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nccl/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nvtx/lib:$LD_LIBRARY_PATH"

# Default parameters for Indonesian language with large model and diarization
MODEL=${1:-"large-v3"}
HOST=${2:-"localhost"}
PORT=${3:-"9002"}
LANGUAGE=${4:-"id"}  # Indonesian language code

echo "Starting WhisperLiveKit server with ADVANCED diarization and large model..."
echo "Model: $MODEL"
echo "Language: $LANGUAGE (Bahasa Indonesia)"
echo "Host: $HOST"
echo "Port: $PORT"
echo "Features: Advanced Speaker Diarization, Large Model, Indonesian Language"
echo "Diarization Models: pyannote/segmentation-3.0 + speechbrain/spkrec-ecapa-voxceleb"
echo "Advanced Features: Punctuation-based speaker splitting, VAC, Confidence validation"
echo "Access the interface at: http://$HOST:$PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server with advanced diarization and Indonesian language
whisperlivekit-server \
  --model "$MODEL" \
  --host "$HOST" \
  --port "$PORT" \
  --language "$LANGUAGE" \
  --diarization \
  --punctuation-split \
  --segmentation-model "pyannote/segmentation-3.0" \
  --embedding-model "speechbrain/spkrec-ecapa-voxceleb" \
  --min-chunk-size 1.0 \
  --vac \
  --confidence-validation 