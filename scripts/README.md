# Scripts Directory
## WhisperLiveKit Server Scripts

This directory contains all the server management scripts for WhisperLiveKit.

## 🚀 FastAPI Scripts

### `run_fastapi_server.sh`
**Modern FastAPI-based web interface**
- **Purpose**: Start the FastAPI server with GPU acceleration
- **Features**: Real-time WebSocket communication, responsive UI, API documentation
- **Usage**: `./scripts/run_fastapi_server.sh [options]`
- **Options**:
  - `--stop`: Stop the running server
  - `--restart`: Restart the server
  - `--status`: Check server status
  - `--help`: Show help information

**Example**:
```bash
# Start the FastAPI server
./scripts/run_fastapi_server.sh

# Check status
./scripts/run_fastapi_server.sh --status

# Stop server
./scripts/run_fastapi_server.sh --stop
```

## 🎤 Original WhisperLiveKit Scripts

### Core Server Scripts

#### `run_server.sh`
**Main server runner with comprehensive configuration**
- **Purpose**: Enhanced server runner with PID management and logging
- **Features**: GPU optimization, background execution, comprehensive logging
- **Usage**: `./scripts/run_server.sh [options]`

#### `run_server_list.sh`
**List all available server configurations**
- **Purpose**: Display all available server configurations
- **Features**: Model options, language support, performance settings

### Model-Specific Scripts

#### English Models
- `run_server_accurate.sh` - High accuracy English model
- `run_server_english.sh` - Standard English model
- `run_server_fast.sh` - Fast English model
- `run_server_large.sh` - Large English model
- `run_server_medium.sh` - Medium English model
- `run_server_small.sh` - Small English model

#### Multilingual Models
- `run_server_multilingual.sh` - Multilingual support
- `run_server_network.sh` - Network-based models

#### Indonesian Models
- `run_server_id_accurate.sh` - High accuracy Indonesian model
- `run_server_id_large.sh` - Large Indonesian model
- `run_server_id_medium.sh` - Medium Indonesian model
- `run_server_id_network.sh` - Network-based Indonesian model
- `run_server_id_simul.sh` - Simultaneous Indonesian model
- `run_server_id_small.sh` - Small Indonesian model
- `run_server_id_very_accurate.sh` - Maximum accuracy Indonesian model
- `run_server_id_very_fast.sh` - High-speed Indonesian model

#### Specialized Scripts
- `run_server_with_diarization_large_id.sh` - Indonesian model with speaker diarization

## 📋 Script Categories

### 🆕 Modern Scripts (Recommended)
- **FastAPI-based**: `run_fastapi_server.sh`
  - Modern web framework
  - Real-time WebSocket communication
  - Responsive UI with Tailwind CSS
  - Automatic API documentation
  - GPU optimization

### 📜 Legacy Scripts
- **Original WhisperLiveKit**: All other `run_server_*.sh` scripts
  - Traditional server implementation
  - Various model configurations
  - Language-specific optimizations

## 🎯 Usage Recommendations

### For New Users
```bash
# Start with FastAPI (recommended)
./scripts/run_fastapi_server.sh
```

### For Specific Languages
```bash
# Indonesian language
./scripts/run_server_id_medium.sh

# English language
./scripts/run_server_english.sh

# Multilingual
./scripts/run_server_multilingual.sh
```

### For Performance Testing
```bash
# Fast model
./scripts/run_server_fast.sh

# Accurate model
./scripts/run_server_accurate.sh

# Large model (best quality)
./scripts/run_server_large.sh
```

## 🔧 Script Features

### Common Features
- **GPU Support**: All scripts support NVIDIA GPU acceleration
- **PID Management**: Background execution with process management
- **Logging**: Comprehensive logging to `./logs/` directory
- **Configuration**: Environment variable support
- **Error Handling**: Graceful error recovery

### FastAPI Script Features
- **Modern UI**: Responsive web interface
- **Real-time**: WebSocket-based communication
- **API Docs**: Automatic OpenAPI documentation
- **Type Safety**: Full type hints and validation
- **CORS Support**: Cross-origin resource sharing

## 📊 Performance Comparison

| Script Type | Performance | UI | GPU Support | Documentation |
|-------------|-------------|----|-------------|---------------|
| `run_fastapi_server.sh` | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| `run_server.sh` | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| `run_server_*.sh` | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

## 🚀 Quick Start

1. **Choose your script**:
   ```bash
   # Modern FastAPI (recommended)
   ./scripts/run_fastapi_server.sh
   
   # Or specific model
   ./scripts/run_server_id_medium.sh
   ```

2. **Access the interface**:
   - **FastAPI**: http://localhost:8000
   - **Legacy**: http://localhost:9001

3. **Monitor logs**:
   ```bash
   tail -f ./logs/*.log
   ```

4. **Stop server**:
   ```bash
   ./scripts/run_fastapi_server.sh --stop
   ```

## 📚 Related Documentation

- **[FastAPI Guide](../docs/FASTAPI_README.md)** - Modern FastAPI application
- **[Dual GPU Guide](../docs/DUAL_GPU_GUIDE.md)** - GPU configuration
- **[Indonesian Scripts](../tests/test_indonesian_scripts.md)** - Indonesian language support

## 🔍 Troubleshooting

### Common Issues
```bash
# Check if server is running
./scripts/run_fastapi_server.sh --status

# Check GPU status
nvidia-smi

# Check logs
tail -f ./logs/fastapi_*.log

# Restart server
./scripts/run_fastapi_server.sh --restart
```

### Script Permissions
```bash
# Make scripts executable
chmod +x ./scripts/*.sh
```

---

*Last Updated: July 31, 2025* 