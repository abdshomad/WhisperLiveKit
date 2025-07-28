#!/bin/bash

# WhisperLiveKit Server Runner
# This script activates the virtual environment and starts the WhisperLiveKit server

# Activate virtual environment
source .venv/bin/activate

# Set environment variables for GPU acceleration
export CUDA_VISIBLE_DEVICES="0,1"
export CT2_CUDA_DEVICES="0,1"

# Set comprehensive library paths for CUDA 12.1 compatibility
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-12.1/targets/x86_64-linux/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_cupti/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_nvrtc/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_runtime/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cufft/lib:/usr/local/lib/python3.10/dist-packages/nvidia/curand/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusolver/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusparse/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nccl/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nvtx/lib:$LD_LIBRARY_PATH"

# Default parameters
MODEL=${1:-"tiny.en"}
HOST=${2:-"localhost"}
PORT=${3:-"9001"}

echo "Starting WhisperLiveKit server..."
echo "Model: $MODEL"
echo "Host: $HOST"
echo "Port: $PORT"
echo "Access the interface at: http://$HOST:$PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
whisperlivekit-server --model "$MODEL" --host "$HOST" --port "$PORT"
