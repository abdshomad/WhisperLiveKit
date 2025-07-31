# WhisperLiveKit FastAPI Application

Modern FastAPI-based web interface for real-time speech recognition with GPU acceleration.

## Features

- 🚀 **FastAPI**: Modern web framework with automatic API docs
- 🎨 **Jinja2 Templates**: Dynamic HTML rendering
- 🎤 **Real-time Transcription**: WebSocket-based speech recognition
- 🖥️ **GPU Acceleration**: NVIDIA H100 optimized
- 📱 **Responsive UI**: Tailwind CSS with mobile support
- 🔧 **Type Safety**: Full type hints and Pydantic models

## Quick Start

### Prerequisites
- Python 3.9+
- NVIDIA GPU with CUDA
- `uv` package manager

### Installation
```bash
# Install dependencies
uv sync

# Check GPU
nvidia-smi
```

### Running
```bash
# Start server
./scripts/run_fastapi_server.sh

# Check status
./scripts/run_fastapi_server.sh --status

# Stop server
./scripts/run_fastapi_server.sh --stop
```

### Access URLs
- **Web Interface**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/api/health

## Project Structure

```
├── main.py                          # FastAPI application
├── run_fastapi_server.sh            # Server management
├── .env                             # Environment configuration
├── templates/                       # Jinja2 templates
│   ├── base.html                   # Base template
│   └── index.html                  # Main interface
├── static/                         # Static assets
│   ├── css/main.css               # Custom styles
│   └── js/main.js                 # Frontend logic
└── pyproject.toml                 # Dependencies
```

## API Endpoints

- `GET /` - Web interface
- `GET /api/health` - Health check
- `GET /api/server-info` - Server info
- `WebSocket /ws/asr` - Real-time transcription

## Environment Configuration

The application supports configuration via environment variables and a `.env` file:

### Environment Variables
- **PORT**: Server port (default: 8000)
- **HOST**: Server host (default: 0.0.0.0)
- **CUDA_VISIBLE_DEVICES**: GPU selection (default: "0")
- **CT2_CUDA_DEVICES**: CTranslate2 devices (default: "0")

### .env File
Create a `.env` file in the project root:
```bash
# WhisperLiveKit FastAPI Configuration
# Based on nvidia-smi output: 2x NVIDIA H100 NVL GPUs
# GPU 0: 85GB/95GB used (89% utilization)
# GPU 1: 4MB/95GB used (essentially free) - OPTIMAL CHOICE
PORT=8000
HOST=0.0.0.0
CUDA_VISIBLE_DEVICES=1
CT2_CUDA_DEVICES=1
```

**GPU Optimization**: The configuration automatically selects the least utilized GPU for optimal performance.

### Usage Examples
```bash
# Use default .env configuration
./run_fastapi_server.sh

# Override port via environment variable
PORT=9000 ./run_fastapi_server.sh

# Override multiple settings
PORT=9000 HOST=127.0.0.1 ./run_fastapi_server.sh
```

## Development

```bash
# Manual start
uv run uvicorn main:app --reload

# Monitor logs
tail -f ./logs/fastapi_*.log
```

## GPU Optimization

### Current Configuration
Based on `nvidia-smi` output:
- **GPU 0**: NVIDIA H100 NVL (85GB/95GB used - 89% utilization)
- **GPU 1**: NVIDIA H100 NVL (4MB/95GB used - essentially free)

**Selected**: GPU 1 for optimal performance

### Monitoring GPU Usage
```bash
# Check GPU status
nvidia-smi

# Monitor GPU usage in real-time
watch -n 1 nvidia-smi

# Check GPU memory usage
nvidia-smi --query-gpu=name,memory.total,memory.free,memory.used --format=csv
```

### Switching GPUs
To use a different GPU, update the `.env` file:
```bash
# Use GPU 0
CUDA_VISIBLE_DEVICES=0
CT2_CUDA_DEVICES=0

# Use GPU 1 (current optimal choice)
CUDA_VISIBLE_DEVICES=1
CT2_CUDA_DEVICES=1

# Use both GPUs
CUDA_VISIBLE_DEVICES=0,1
CT2_CUDA_DEVICES=0,1
```

## Troubleshooting

### GPU Issues
```bash
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"
```

### Port Issues
```bash
lsof -i :8000
kill -9 <PID>
```

## Improvements over Original

- ✅ Modern FastAPI framework
- ✅ Jinja2 template engine
- ✅ Type safety with Pydantic
- ✅ Automatic API documentation
- ✅ Responsive Tailwind UI
- ✅ Better error handling
- ✅ Real-time status monitoring
- ✅ Accessibility compliance

## License

MIT License 