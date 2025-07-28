# Recording Feature for WhisperLiveKit

This document describes the recording functionality that has been added to WhisperLiveKit, allowing users to save audio recordings with transcriptions and playback capabilities.

## Features

### 🎵 Recording Management
- **Automatic Recording**: Recordings are automatically started when a WebSocket connection is established
- **Audio Storage**: Audio files are saved in the `recordings/` folder
- **Database Storage**: Recording metadata is stored in SQLite database (`recordings.db`)
- **Transcription Storage**: Transcriptions are automatically saved with recordings

### 🎧 Playback Functionality
- **Web Interface**: Built-in audio player in the web interface
- **Download Support**: Recordings can be downloaded as WAV files
- **Recording List**: View all recordings with metadata (duration, file size, creation date)

### 📊 Recording Metadata
- **Title**: Auto-generated title with timestamp
- **Duration**: Recording duration in seconds
- **File Size**: Size of the audio file
- **Transcription**: Full transcription text
- **Creation Date**: When the recording was created
- **Session ID**: Unique session identifier

## API Endpoints

### Recording Management
- `GET /api/recordings` - Get all recordings
- `GET /api/recordings/{id}` - Get specific recording
- `GET /api/recordings/{id}/download` - Download recording file
- `PUT /api/recordings/{id}` - Update recording details
- `DELETE /api/recordings/{id}` - Delete recording

### Recording Control
- `POST /api/recordings/start` - Start a new recording
- `POST /api/recordings/stop` - Stop current recording
- `GET /api/recordings/status` - Get recording status

## Database Schema

The SQLite database (`recordings.db`) contains a `recordings` table with the following fields:

```sql
CREATE TABLE recordings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    title TEXT,
    description TEXT,
    duration REAL,
    file_size INTEGER,
    transcription TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## File Structure

```
whisperlivekit/
├── database.py              # SQLite database operations
├── recording_manager.py     # Recording management logic
├── basic_server.py          # Updated server with recording endpoints
├── web/
│   └── live_transcription.html  # Updated web interface
└── recordings/              # Audio files storage
    └── recording_*.wav      # Recorded audio files
```

## Usage

### Starting the Server
```bash
# Run with CPU-only mode (recommended for testing)
CUDA_VISIBLE_DEVICES="" python -m whisperlivekit.basic_server --host 0.0.0.0 --port 8000 --model tiny

# Run with GPU support
python -m whisperlivekit.basic_server --host 0.0.0.0 --port 8000 --model tiny
```

### Web Interface
1. Open `http://localhost:8000` in your browser
2. Click the record button to start transcription
3. Speak into your microphone
4. Click stop to end the recording
5. View saved recordings in the "Rekaman Tersimpan" section
6. Use the playback controls to listen to recordings

### API Usage
```bash
# Get all recordings
curl http://localhost:8000/api/recordings

# Get recording status
curl http://localhost:8000/api/recordings/status

# Start recording
curl -X POST http://localhost:8000/api/recordings/start

# Stop recording
curl -X POST http://localhost:8000/api/recordings/stop

# Download recording
curl http://localhost:8000/api/recordings/1/download -o recording.wav

# Delete recording
curl -X DELETE http://localhost:8000/api/recordings/1
```

## Implementation Details

### Recording Flow
1. **WebSocket Connection**: When a client connects via WebSocket, recording automatically starts
2. **Audio Processing**: Audio chunks are sent to the server and processed for transcription
3. **Storage**: Audio chunks and transcriptions are stored in memory during recording
4. **Saving**: When recording stops, audio is saved to file and metadata to database
5. **Cleanup**: Recording session is cleaned up and resources are freed

### Audio Format
- **Input**: WebM audio from browser's MediaRecorder API
- **Storage**: Raw PCM data (can be enhanced to support proper WAV format)
- **Playback**: Served as WAV files for browser compatibility

### Database Operations
- **Automatic Creation**: Database and tables are created automatically on first run
- **Transaction Safety**: All database operations use proper transaction handling
- **Error Handling**: Comprehensive error handling for database operations

## Future Enhancements

### Planned Features
- [ ] Proper WAV file format support
- [ ] Audio compression options
- [ ] Recording quality settings
- [ ] Bulk operations (delete multiple recordings)
- [ ] Recording search and filtering
- [ ] Export transcriptions to various formats
- [ ] Recording categories and tags

### Technical Improvements
- [ ] Better audio format handling
- [ ] Streaming audio playback
- [ ] Real-time recording status updates
- [ ] Recording encryption
- [ ] Cloud storage integration

## Troubleshooting

### Common Issues

1. **Server won't start**: Check if port 8000 is available
2. **CUDA errors**: Use `CUDA_VISIBLE_DEVICES=""` for CPU-only mode
3. **Database errors**: Check file permissions for `recordings.db`
4. **Audio not recording**: Ensure microphone permissions are granted

### Logs
Check server logs for detailed error information:
```bash
# View server logs
tail -f /var/log/whisperlivekit.log
```

## Contributing

To contribute to the recording feature:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This feature is part of WhisperLiveKit and follows the same license terms. 