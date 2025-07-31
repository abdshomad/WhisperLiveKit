# Dual GPU Configuration Guide

## Overview

This guide explains how to configure WhisperLiveKit to use both NVIDIA H100 NVL GPUs for maximum performance.

## Current GPU Setup

Based on `nvidia-smi` output:
- **GPU 0**: NVIDIA H100 NVL (85GB/95GB used - 89% utilization)
- **GPU 1**: NVIDIA H100 NVL (4MB/95GB used - essentially free)

**Total Available**: 190GB GPU memory across 2 GPUs

## Configuration Options

### 1. Single GPU (Current Default)
```bash
# .env file
CUDA_VISIBLE_DEVICES=1
CT2_CUDA_DEVICES=1
```
**Use Case**: When you want to avoid GPU 0 (heavily loaded)

### 2. Dual GPU (Maximum Performance)
```bash
# .env file
CUDA_VISIBLE_DEVICES=0,1
CT2_CUDA_DEVICES=0,1
```
**Use Case**: Maximum performance, parallel processing

### 3. GPU 0 Only
```bash
# .env file
CUDA_VISIBLE_DEVICES=0
CT2_CUDA_DEVICES=0
```
**Use Case**: When GPU 1 is busy with other tasks

## Performance Benefits of Dual GPU

### Memory Distribution
- **GPU 0**: 10GB free (85GB used)
- **GPU 1**: 95GB free (4MB used)
- **Total Free**: 105GB available

### Processing Capabilities
- **Parallel Model Loading**: Load different models on each GPU
- **Batch Processing**: Distribute audio processing across GPUs
- **Redundancy**: Fallback if one GPU becomes unavailable

## Implementation

### Current Dual GPU Configuration
```bash
# .env file
PORT=8000
HOST=0.0.0.0
CUDA_VISIBLE_DEVICES=0,1
CT2_CUDA_DEVICES=0,1
```

### Verification
```bash
# Check configuration
./scripts/run_fastapi_server.sh --help

# Expected output:
# GPU Configuration:
# - CUDA_VISIBLE_DEVICES: 0,1
# - CT2_CUDA_DEVICES: 0,1
```

## Monitoring Dual GPU Usage

### Real-time Monitoring
```bash
# Monitor both GPUs
watch -n 1 nvidia-smi

# Check memory usage
nvidia-smi --query-gpu=index,name,memory.total,memory.free,memory.used --format=csv

# Monitor GPU utilization
nvidia-smi --query-gpu=index,utilization.gpu,utilization.memory --format=csv
```

### Application Monitoring
```bash
# Check server logs
tail -f ./logs/fastapi_*.log

# Monitor GPU usage during transcription
nvidia-smi -l 1
```

## Performance Optimization

### 1. Model Distribution
- **GPU 0**: Large models (whisper-large-v3)
- **GPU 1**: Smaller models (whisper-base, whisper-small)

### 2. Batch Processing
- Process multiple audio streams simultaneously
- Distribute chunks across available GPUs

### 3. Memory Management
- Monitor memory usage on both GPUs
- Adjust batch sizes based on available memory

## Troubleshooting

### GPU Memory Issues
```bash
# Check memory usage
nvidia-smi

# Kill processes using GPU memory
sudo fuser -v /dev/nvidia*

# Reset GPU state (if needed)
sudo nvidia-smi --gpu-reset
```

### Performance Issues
```bash
# Check GPU utilization
nvidia-smi -l 1

# Monitor temperature
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits
```

### Application Errors
```bash
# Check server logs
tail -f ./logs/fastapi_*.log

# Restart with single GPU if needed
CUDA_VISIBLE_DEVICES=1 ./scripts/run_fastapi_server.sh
```

## Switching Configurations

### To Single GPU (GPU 1)
```bash
# Update .env file
CUDA_VISIBLE_DEVICES=1
CT2_CUDA_DEVICES=1
```

### To Single GPU (GPU 0)
```bash
# Update .env file
CUDA_VISIBLE_DEVICES=0
CT2_CUDA_DEVICES=0
```

### To Dual GPU
```bash
# Update .env file
CUDA_VISIBLE_DEVICES=0,1
CT2_CUDA_DEVICES=0,1
```

## Best Practices

### 1. Memory Management
- Monitor memory usage on both GPUs
- Avoid running other GPU-intensive tasks
- Use appropriate model sizes for available memory

### 2. Performance Monitoring
- Regularly check GPU utilization
- Monitor temperature and power usage
- Track transcription performance

### 3. Configuration Management
- Keep backup configurations
- Document performance differences
- Test with different model sizes

## Expected Performance

### Single GPU (GPU 1)
- **Memory**: 95GB available
- **Performance**: High (no contention)
- **Use Case**: Standard transcription

### Dual GPU
- **Memory**: 105GB available
- **Performance**: Maximum (parallel processing)
- **Use Case**: High-throughput, multiple models

### Single GPU (GPU 0)
- **Memory**: 10GB available
- **Performance**: Limited (high contention)
- **Use Case**: Emergency fallback only

## Commands Summary

```bash
# Check current GPU status
nvidia-smi

# Start with dual GPU (current config)
./scripts/run_fastapi_server.sh

# Start with single GPU (GPU 1)
CUDA_VISIBLE_DEVICES=1 ./scripts/run_fastapi_server.sh

# Monitor GPU usage
watch -n 1 nvidia-smi

# Check server status
./scripts/run_fastapi_server.sh --status

# Stop server
./scripts/run_fastapi_server.sh --stop
```

## Current Recommendation

**Use Dual GPU Configuration** (current setup):
- Maximum performance with 105GB available memory
- Parallel processing capabilities
- Redundancy if one GPU becomes unavailable
- Optimal for high-throughput transcription tasks 