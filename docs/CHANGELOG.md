# Changelog

All notable changes to WhisperLiveKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Server Information API**: New `/server-info` endpoint providing real-time server configuration
- **Dynamic WebSocket URL Configuration**: Automatic URL detection based on browser location
- **Enhanced UI Components**:
  - Real-time waveform visualization during recording
  - Recording button animations with visual feedback
  - Timer display with MM:SS format
  - Status indicators for connection and processing states
- **Speaker Diarization Support**:
  - Multi-speaker identification with labels
  - Real-time buffer display for ongoing transcription
  - Lag indicators for transcription and diarization processes
  - Silence detection and display
- **Advanced Audio Processing**:
  - Configurable chunk sizes (500ms to 5000ms)
  - Real-time audio visualization using Canvas API
  - Improved MediaRecorder integration
- **Server Information Display**:
  - Dynamic server info fetching from `/server-info` endpoint
  - Real-time server status display in footer
  - Model and configuration information visibility
  - Backend and task information display
- **Comprehensive Run Scripts Collection**:
  - **Base Scripts**: `run_server.sh` - Main server runner with H100 GPU optimization
  - **Model-Specific Scripts**:
    - `run_server_small.sh` - Fast processing with small model
    - `run_server_medium.sh` - Balanced speed/accuracy with medium model
    - `run_server_large.sh` - High accuracy with large-v3 model
    - `run_server_fast.sh` - Maximum speed optimization
    - `run_server_accurate.sh` - Maximum accuracy with diarization
  - **Language-Specific Scripts**:
    - `run_server_english.sh` - English language optimization
    - `run_server_multilingual.sh` - Multi-language support
  - **Network Scripts**:
    - `run_server_network.sh` - Network accessible server (0.0.0.0)
  - **Indonesian-Specific Scripts** (8 scripts):
    - `run_server_id_small.sh` - Fast Indonesian processing
    - `run_server_id_medium.sh` - Balanced Indonesian processing
    - `run_server_id_large.sh` - High accuracy Indonesian processing
    - `run_server_id_network.sh` - Network accessible Indonesian server
    - `run_server_id_accurate.sh` - Maximum accuracy Indonesian processing
    - `run_server_id_very_accurate.sh` - Professional quality Indonesian processing
    - `run_server_id_very_fast.sh` - Maximum speed Indonesian processing
    - `run_server_id_simul.sh` - Real-time Indonesian processing
  - **Management Scripts**:
    - `run_server_list.sh` - Overview of all available scripts
    - `run_server_id_list.sh` - Indonesian scripts overview
    - `test_indonesian_scripts.sh` - Comprehensive testing framework

### Changed
- **WebSocket Communication**: Enhanced connection management with automatic reconnection
- **Error Handling**: Improved error handling for network issues and connection failures
- **UI/UX**: Modern, responsive interface design with better user feedback
- **Server Architecture**: FastAPI lifespan management for proper resource initialization
- **Logging**: Structured logging with different levels (INFO, DEBUG, WARNING)
- **Server Management**: Enhanced PID-based background execution with comprehensive logging
- **Script Organization**: Categorized scripts by purpose (model, language, network, management)

### Improved
- **Connection Lifecycle**: Graceful disconnection handling and proper cleanup
- **Resource Management**: Better memory management to prevent leaks
- **Cross-Origin Support**: CORS middleware for cross-origin requests
- **SSL Support**: Enhanced secure connection capabilities
- **Mobile Compatibility**: Responsive design for different screen sizes
- **Server Deployment**: Streamlined server startup with pre-configured scripts
- **Indonesian Language Support**: Optimized scripts for Indonesian language processing
- **Testing Framework**: Comprehensive testing for Indonesian-specific scripts

### Fixed
- **WebSocket URL Configuration**: Automatic protocol detection (ws/wss) based on page protocol
- **Audio Context Management**: Proper cleanup of audio resources
- **Server State Management**: Better handling of server configuration and state
- **Connection Stability**: Robust error handling for lost connections
- **Script Execution**: Fixed PID management and background execution issues
- **Indonesian Scripts**: Resolved language-specific configuration problems

## [0.2.2] - 2024-01-XX

### Added
- Initial release of WhisperLiveKit
- Basic WebSocket-based real-time transcription
- Support for multiple Whisper models
- Speaker diarization capabilities
- Web interface for audio transcription

### Changed
- Refactored from standalone server to Python library structure
- Encapsulated Whisper functionality into WhisperLiveKit library
- Improved project organization and maintainability

---

## Version History

### Current Version: 0.2.2
- **Status**: Stable release with enhanced features
- **Key Features**: Real-time transcription, speaker diarization, web interface
- **Architecture**: Python library with FastAPI server component

### Previous Versions
- **0.2.1**: Initial library structure implementation
- **0.2.0**: Basic WebSocket server functionality
- **0.1.x**: Development and testing versions

---

## Migration Guide

### From Previous Versions
- **WebSocket URL**: Now auto-detected from browser location
- **Server Configuration**: Available via `/server-info` endpoint
- **UI Changes**: Enhanced interface with real-time feedback
- **Audio Processing**: Improved chunk size configuration

### Breaking Changes
- None in current version
- All changes are backward compatible

---

## Contributing

When adding new features or making changes, please:
1. Update this changelog with appropriate entries
2. Follow the [Keep a Changelog](https://keepachangelog.com/) format
3. Use semantic versioning for releases
4. Document any breaking changes clearly

---

## Release Notes

### Latest Release (Unreleased)
This release focuses on enhancing the user experience and server functionality:

**Key Improvements:**
- Real-time server information display
- Dynamic WebSocket URL configuration
- Enhanced UI with modern design
- Improved error handling and connection management
- Better resource management and cleanup

**New Features:**
- Server information API endpoint
- Real-time waveform visualization
- Advanced speaker diarization display
- Configurable audio chunk sizes
- Mobile-responsive design
- Comprehensive run script collection (20+ scripts)
- Indonesian language optimization scripts
- Network-accessible server configurations
- Testing framework for script validation

**Technical Enhancements:**
- FastAPI lifespan management
- Structured logging system
- CORS middleware support
- SSL certificate handling
- Graceful connection termination
- PID-based background execution
- Comprehensive script management system
- Indonesian language processing optimization 