# Enhanced Logging and Version Features for WhisperLiveKit

## Overview

This document summarizes the comprehensive logging mechanism and version information features that have been implemented for the WhisperLiveKit project. These enhancements provide better debugging capabilities and version tracking.

## 🎯 Features Implemented

### 1. Enhanced Logging System (`whisperlivekit/enhanced_logging.py`)

#### Comprehensive System Information Logging
- **Python Version**: Current Python version and build information
- **Platform Details**: Operating system and architecture
- **Working Directory**: Current project location
- **Log File Location**: Timestamped log files in `logs/` directory
- **Start Time**: ISO format timestamp of server startup

#### GPU and CUDA Information
- **PyTorch Version**: Current PyTorch installation version
- **CUDA Availability**: Whether CUDA is available
- **CUDA Version**: Installed CUDA version
- **GPU Count**: Number of available GPUs
- **GPU Details**: Model names for each GPU
- **GPU Memory**: Allocated and cached memory for each GPU

#### Environment Variables Tracking
- **CUDA_VISIBLE_DEVICES**: GPU device selection
- **CT2_CUDA_DEVICES**: CTranslate2 device configuration
- **PATH**: System PATH for debugging

#### Specialized Logging Methods
- **WebSocket Events**: Connection, disconnection, and message logging
- **Recording Events**: Save, load, update, and delete operations
- **API Requests**: HTTP method, endpoint, status code, and performance metrics
- **Transcription Events**: Chunk processing and result handling
- **Error Context**: Full stack traces with additional context
- **Performance Metrics**: Response times and memory usage

### 2. Version Information System (`whisperlivekit/version_info.py`)

#### Git Information
- **Current Branch**: Active git branch name
- **Commit Hash**: Short commit hash (8 characters)
- **Last Commit Message**: Most recent commit message
- **Build Date**: Last commit date or current timestamp

#### Dependency Versions
- **PyTorch**: Current PyTorch version
- **Transformers**: Hugging Face transformers version
- **Faster-Whisper**: CTranslate2 faster-whisper version
- **FastAPI**: Web framework version

#### Version Display Methods
- **Version Dictionary**: Complete version information as JSON
- **Version String**: Formatted version string with git info
- **Footer Info**: Simplified version info for web interface

### 3. Enhanced Web Interface (`whisperlivekit/web/live_transcription_with_recordings_enhanced.html`)

#### Footer with Version Information
- **Version Display**: Shows version, branch, and commit
- **Build Date**: Last compilation/build date
- **Connection Status**: WebSocket connection status
- **Server Information**: Model and configuration details

#### Debug Console
- **Toggle Debug Mode**: Show/hide debug console
- **Real-time Logging**: WebSocket and API event logging
- **Timestamped Messages**: All debug messages with timestamps

#### Enhanced UI Features
- **Modern Design**: Gradient backgrounds and smooth animations
- **Responsive Layout**: Mobile-friendly design
- **Status Indicators**: Visual connection and recording status
- **Error Handling**: Graceful error display and recovery

### 4. Enhanced Server (`whisperlivekit/server_with_recordings_enhanced.py`)

#### Comprehensive Request Logging
- **HTTP Middleware**: Logs all incoming requests
- **Performance Metrics**: Response time tracking
- **Client Information**: IP address and user agent
- **Error Tracking**: Full error context with stack traces

#### Enhanced API Endpoints
- **Version Endpoint**: `/version` for detailed version info
- **Enhanced Server Info**: `/server-info` with version details
- **Recording APIs**: Full CRUD operations with logging

#### Memory and GPU Monitoring
- **Memory Usage**: RSS and VMS memory tracking
- **GPU Memory**: Per-GPU memory allocation monitoring
- **Startup Metrics**: Initial system state logging

## 📊 Log File Structure

### Timestamped Log Files
```
logs/whisperlivekit_YYYYMMDD_HHMMSS.log
```

### Log Format
```
TIMESTAMP | LEVEL | MODULE | FUNCTION:LINE | MESSAGE
```

### Example Log Entries
```
2025-07-31 12:21:01,727 | INFO | whisperlivekit | info:142 | === SYSTEM INFORMATION ===
2025-07-31 12:21:01,727 | INFO | whisperlivekit | info:142 | Python Version: 3.11.13
2025-07-31 12:21:01,791 | INFO | whisperlivekit | info:142 | CUDA Available: True
2025-07-31 12:21:01,856 | INFO | whisperlivekit | info:142 | GPU 0: NVIDIA H100 NVL
2025-07-31 12:21:09,294 | INFO | whisperlivekit | info:142 | API GET /server-info | Status: 200 | Duration: 0.70ms
```

## 🧪 Test Server (`test_enhanced_server.py`)

### Features Demonstrated
- **Enhanced Logging**: All logging features without Whisper model
- **Version Information**: Complete version tracking
- **API Testing**: Interactive web interface for testing
- **Database Operations**: Recording CRUD operations
- **Performance Metrics**: Request/response timing

### Web Interface Features
- **Test Buttons**: Interactive API testing
- **Version Display**: Real-time version information
- **Results Display**: JSON response formatting
- **Error Handling**: Graceful error display

## 🚀 Usage

### Running the Enhanced Server
```bash
# Run the enhanced server with comprehensive logging
./run_enhanced_server.sh

# Or run the test server (no Whisper model)
source .venv/bin/activate
python test_enhanced_server.py
```

### Accessing the Web Interface
- **Main Interface**: http://localhost:9002/
- **Server Info**: http://localhost:9002/server-info
- **Version Info**: http://localhost:9002/version
- **Recordings API**: http://localhost:9002/api/recordings

### Viewing Logs
```bash
# View latest log file
ls -la logs/ | tail -1
tail -f logs/whisperlivekit_*.log

# Search for specific events
grep "API" logs/whisperlivekit_*.log
grep "ERROR" logs/whisperlivekit_*.log
```

## 📈 Benefits

### For Developers
- **Comprehensive Debugging**: Detailed system and application logs
- **Performance Monitoring**: Request timing and memory usage
- **Error Tracking**: Full context for debugging issues
- **Version Tracking**: Clear version and build information

### For Users
- **Transparent Operation**: Visible server status and version
- **Better Error Messages**: Clear error descriptions
- **Debug Console**: Real-time debugging information
- **Version Awareness**: Know which version is running

### For Operations
- **System Monitoring**: GPU and memory usage tracking
- **Request Analytics**: API usage patterns and performance
- **Error Analysis**: Detailed error logs for troubleshooting
- **Version Management**: Clear version tracking across deployments

## 🔧 Configuration

### Log Level Control
```python
# In enhanced_logging.py
enhanced_logger = EnhancedLogger(log_level="INFO")  # DEBUG, INFO, WARNING, ERROR, CRITICAL
```

### Version Information
```python
# In version_info.py
version_info = VersionInfo()
version_info.version = "1.0.0"  # Set custom version
```

### Log File Location
```python
# Logs are automatically created in logs/ directory
# Format: whisperlivekit_YYYYMMDD_HHMMSS.log
```

## 🎉 Summary

The enhanced logging and version features provide:

1. **Comprehensive System Monitoring**: GPU, memory, and environment tracking
2. **Detailed Application Logging**: Request/response, WebSocket, and database operations
3. **Version Information Display**: Git branch, commit, and build date in web interface
4. **Debug Console**: Real-time debugging information for developers
5. **Performance Metrics**: Response times and resource usage tracking
6. **Error Context**: Full stack traces with additional debugging information

These enhancements significantly improve the debugging capabilities and user experience of the WhisperLiveKit application, making it easier to identify and resolve issues while providing clear version and status information to users. 