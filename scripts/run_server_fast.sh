#!/bin/bash

# WhisperLiveKit Fast Server for H100x2
# Optimized for maximum speed with small model and enhanced library path

# Configuration for maximum speed (only set what differs from defaults)
SCRIPT_NAME="WhisperLiveKit Fast Server (H100x2)"
SCRIPT_DESCRIPTION="This script runs WhisperLiveKit server optimized for maximum speed."
DEFAULT_MODEL="small"
CONFIG_DESCRIPTION="- Model: small (fastest processing, lower accuracy)
- Diarization: disabled (for maximum speed)
- Enhanced H100 library path for CUDA compatibility
- Background execution with PID management"
USAGE_EXAMPLES="  $0                                    # Use default settings
  $0 --port 9002                       # Change port
  $0 --language en                     # Set language to English
  $0 --stop                           # Stop server
  $0 --restart                        # Restart server
  $0 --help                           # Show this help"
RECOMMENDED_USE="⚡ SPEED OPTIMIZED: Fastest processing with lower accuracy
   Use this for real-time applications where speed is critical."

# Activate virtual environment
source .venv/bin/activate

# Set environment variables for H100 GPU acceleration
export CUDA_VISIBLE_DEVICES="0,1"
export CT2_CUDA_DEVICES="0,1"

# Enhanced library path for H100 compatibility (from run_server.sh)
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-12.1/targets/x86_64-linux/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_cupti/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_nvrtc/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_runtime/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cufft/lib:/usr/local/lib/python3.10/dist-packages/nvidia/curand/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusolver/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusparse/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nccl/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nvtx/lib:$LD_LIBRARY_PATH"

# Execute the base script with our configuration
exec ./scripts/run_server.sh "$@" 