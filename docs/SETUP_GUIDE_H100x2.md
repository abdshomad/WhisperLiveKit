# WhisperLiveKit Setup Guide

## Installation Summary

✅ **Successfully installed WhisperLiveKit** using `uv` and `.venv` virtual environment

### What was installed:
- **WhisperLiveKit**: Core package (development mode)
- **FFmpeg**: Audio processing dependency ✅ (already installed)
- **PyTorch**: CUDA-enabled version for H100 GPU acceleration ✅
- **Diart**: For speaker diarization
- **CTranslate2**: GPU-optimized version for faster inference

### Virtual Environment:
- Using `.venv` virtual environment
- Managed with `uv` for fast Python package management

### GPU Setup:
- Configured for 2x H100 GPUs with CUDA 12.1
- CTranslate2 optimized for cuDNN 8 compatibility
- Server runs on port 9001 with GPU acceleration

## CUDA Environment Setup

### 1. Set CUDA Environment Variables:
```bash
# Set CUDA paths
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Verify CUDA installation
nvcc --version
nvidia-smi
```

### 2. Verify GPU Detection:
```bash
# Activate virtual environment
source .venv/bin/activate

# Check PyTorch CUDA support
python -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('GPU count:', torch.cuda.device_count())"
```

### 3. Install GPU-Optimized Dependencies:
```bash
# Install CUDA-enabled PyTorch
uv pip install torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cu121

# Install compatible CTranslate2 for cuDNN 8
uv pip install ctranslate2==3.22.0
```

## Quick Start

### 1. Activate the environment:
```bash
source .venv/bin/activate
```

### 2. Start the server:
```bash
# Using the convenience script (recommended)
./run_server.sh

# Or directly with uv
source .venv/bin/activate && whisperlivekit-server --model tiny.en
```

### Server Configuration:
The `run_server.sh` script includes:
- GPU environment setup (`CUDA_VISIBLE_DEVICES="0,1"`)
- CTranslate2 GPU configuration (`CT2_CUDA_DEVICES="0,1"`)
- Library path configuration for cuDNN compatibility
- Default port 9001 configuration

### 3. Access the interface:
Open your browser at `http://localhost:9001`

## Available Models

- **tiny.en**: Fastest, English only
- **tiny**: Fast, multilingual
- **base.en**: Good balance, English only
- **base**: Good balance, multilingual
- **small.en**: Better accuracy, English only
- **small**: Better accuracy, multilingual
- **medium.en**: High accuracy, English only
- **medium**: High accuracy, multilingual
- **large-v3**: Best accuracy, multilingual

## Advanced Usage

### With Speaker Diarization:
```bash
whisperlivekit-server --model medium --diarization --language auto
```

### With SimulStreaming (ultra-low latency):
```bash
whisperlivekit-server --backend simulstreaming --model large-v3 --frame-threshold 20
```

### Custom Configuration:
```bash
whisperlivekit-server \
  --model medium \
  --host 0.0.0.0 \
  --port 9001 \
  --diarization \
  --language auto \
  --vac \
  --confidence-validation
```

## Optional Dependencies

To install additional features:

```bash
# Activate environment first
source .venv/bin/activate

# Original Whisper backend
uv pip install whisperlivekit[whisper]

# Improved timestamps
uv pip install whisperlivekit[whisper-timestamped]

# Apple Silicon optimization
uv pip install whisperlivekit[mlx-whisper]

# OpenAI API integration
uv pip install whisperlivekit[openai]

# SimulStreaming backend
uv pip install whisperlivekit[simulstreaming]

# Sentence-based buffer trimming
uv pip install mosestokenizer wtpsplit
```

## Troubleshooting

### CUDA/GPU Issues:

#### Common cuDNN Errors:
If you see errors like `Unable to load any of {libcudnn_ops.so.9.1.0, libcudnn_ops.so.9.1, libcudnn_ops.so.9, libcudnn_ops.so}`:

1. **Check cuDNN version compatibility:**
   ```bash
   # Check installed cuDNN version
   find /usr/local -name "*cudnn*" | grep lib
   ```

2. **Install compatible CTranslate2 version:**
   ```bash
   # For cuDNN 8 systems
   uv pip install ctranslate2==3.22.0
   
   # For cuDNN 9 systems
   uv pip install ctranslate2==4.6.0
   ```

3. **Set proper library paths in run_server.sh:**
   ```bash
   export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-12.1/targets/x86_64-linux/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_cupti/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_nvrtc/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cuda_runtime/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cufft/lib:/usr/local/lib/python3.10/dist-packages/nvidia/curand/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusolver/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cusparse/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nccl/lib:/usr/local/lib/python3.10/dist-packages/nvidia/nvtx/lib:$LD_LIBRARY_PATH"
   ```

4. **Create symbolic links for CUDA library compatibility:**
   ```bash
   sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib/libcublas.so.12 /usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib/libcublas.so.11
   sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn.so.9
   sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.9
   sudo ln -sf /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.8 /usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/libcudnn_ops.so.9.1
   ```

#### GPU Memory Issues:
- H100 GPUs have 80GB+ memory - suitable for large models
- Monitor GPU usage: `nvidia-smi`
- Use smaller models if memory is constrained

#### CUDA Version Mismatch:
- Ensure PyTorch CUDA version matches system CUDA
- For CUDA 12.1: `uv pip install torch --index-url https://download.pytorch.org/whl/cu121`

### Port Already in Use:
```bash
whisperlivekit-server --port 9002
```

### Memory Issues with Large Models:
- Use smaller models (tiny, base, small) for limited memory
- Ensure sufficient RAM for larger models

## Complete Installation Process

### 1. Clone and Setup Environment:
```bash
git clone https://github.com/QuentinFuxa/WhisperLiveKit
cd WhisperLiveKit
```

### 2. Setup CUDA Environment:
```bash
# Set CUDA paths
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Verify CUDA installation
nvcc --version
nvidia-smi
```

### 3. Install with uv:
```bash
# Install in development mode
uv pip install -e .

# Install GPU-optimized PyTorch
uv pip install torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cu121

# Install compatible CTranslate2
uv pip install ctranslate2==3.22.0

# Install additional dependencies
uv pip install torch diart
```

### 4. Verify Installation:
```bash
# Check GPU support
source .venv/bin/activate
python -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('GPU count:', torch.cuda.device_count())"

# Test server startup
timeout 10s ./run_server.sh || echo "Server test completed"
```

## Development

Since this is installed in development mode (`-e .`), any changes to the source code will be immediately available without reinstalling.

## Next Steps

1. Test the basic functionality with `./run_server.sh`
2. Try different models based on your needs
3. Explore speaker diarization for multi-speaker scenarios
4. Consider SimulStreaming for ultra-low latency applications 