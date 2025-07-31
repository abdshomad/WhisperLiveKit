# WhisperLiveKit Recordings Feature

This document describes the new recordings feature that has been implemented in the WhisperLiveKit project.

## Overview

The recordings feature allows users to:
- Save live transcription sessions to a SQLite database
- View and manage saved recordings
- Edit recording titles
- Delete recordings
- View detailed recording information including transcripts

## Features

### 1. Save Recordings
- After completing a live transcription session, users can save the transcript
- Recording metadata includes:
  - Title (user-defined)
  - Transcript text
  - Duration
  - Model information
  - Language
  - Diarization settings
  - Creation timestamp

### 2. List Recordings
- View all saved recordings in a card-based interface
- Each recording card shows:
  - Title
  - Duration
  - Creation date
  - Model information
  - Preview of transcript

### 3. Playback/View Recordings
- Click "Play" to view detailed recording information
- Modal popup shows complete transcript and metadata
- Full transcript is displayed in a scrollable area

### 4. Edit Recordings
- Edit recording titles
- Changes are saved immediately to the database

### 5. Delete Recordings
- Remove recordings from the database
- Confirmation dialog prevents accidental deletion

## Technical Implementation

### Database
- **Database**: SQLite (`recordings.db`)
- **Table**: `recordings`
- **Fields**:
  - `id` (PRIMARY KEY)
  - `title` (TEXT)
  - `transcript` (TEXT)
  - `duration` (INTEGER)
  - `created_at` (TIMESTAMP)
  - `model_info` (TEXT)
  - `language` (TEXT)
  - `diarization_enabled` (BOOLEAN)

### API Endpoints

#### GET `/api/recordings`
- Returns all recordings
- Response: `{"success": true, "recordings": [...]}`

#### POST `/api/recordings`
- Saves a new recording
- Request body: `{"title": "...", "transcript": "...", "duration": 0, ...}`
- Response: `{"success": true, "recording_id": 1, "message": "..."}`

#### GET `/api/recordings/{id}`
- Returns a specific recording
- Response: `{"success": true, "recording": {...}}`

#### PUT `/api/recordings/{id}/title`
- Updates recording title
- Request body: `{"title": "new title"}`
- Response: `{"success": true, "message": "..."}`

#### DELETE `/api/recordings/{id}`
- Deletes a recording
- Response: `{"success": true, "message": "..."}`

### Web Interface

#### Tabbed Interface
- **Live Transcription Tab**: Original transcription interface with save functionality
- **Saved Recordings Tab**: List and manage saved recordings

#### Save Recording Section
- Appears after completing a transcription session
- Allows user to enter a title and save the recording
- Automatically populated with timestamp-based default title

#### Recordings List
- Grid layout of recording cards
- Each card shows key information and action buttons
- Responsive design for different screen sizes

## Usage

### Running the Server

1. **With Full Whisper Model** (requires GPU):
```bash
./run_server_with_recordings.sh
```

2. **Test Server** (without Whisper model):
```bash
python test_simple_server.py
```

3. **Access the Web Interface**:
- Open browser to `http://localhost:9002`
- Use the tabbed interface to switch between live transcription and saved recordings

### Testing the API

Run the test script to verify all API endpoints:
```bash
python test_recordings_api.py
```

### Testing the Web Interface

Open the test HTML file in a browser:
```bash
# Serve the test file
python -m http.server 8080
# Then open http://localhost:8080/test_web_interface.html
```

## Files Added/Modified

### New Files
- `whisperlivekit/database.py` - SQLite database operations
- `whisperlivekit/server_with_recordings.py` - Enhanced server with recordings API
- `run_server_with_recordings.sh` - Script to run the server on port 9002
- `test_simple_server.py` - Test server without Whisper model
- `test_recordings_api.py` - API testing script
- `test_web_interface.html` - Test web interface
- `whisperlivekit/web/live_transcription_with_recordings.html` - Enhanced web interface

### Modified Files
- `whisperlivekit/web/web_interface.py` - Updated to use new HTML file

## Database Schema

```sql
CREATE TABLE recordings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    transcript TEXT NOT NULL,
    duration INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    model_info TEXT,
    language TEXT,
    diarization_enabled BOOLEAN DEFAULT 0
);
```

## Port Configuration

The recordings feature runs on **port 9002** to avoid conflicts with existing services on ports 9000 and 9001.

## Future Enhancements

1. **Audio Playback**: Add ability to play back the original audio
2. **Export Features**: Export recordings to various formats (PDF, TXT, etc.)
3. **Search and Filter**: Add search functionality for recordings
4. **Categories/Tags**: Organize recordings with tags or categories
5. **Sharing**: Share recordings via links or export
6. **Backup**: Automatic backup of recordings database

## Troubleshooting

### Database Issues
- Check if `recordings.db` file exists in the project root
- Verify SQLite is installed: `sqlite3 --version`
- Check file permissions for database file

### Server Issues
- Ensure port 9002 is not in use: `lsof -i :9002`
- Check server logs for error messages
- Verify all dependencies are installed

### Web Interface Issues
- Check browser console for JavaScript errors
- Verify API endpoints are accessible
- Test with the simple test server first

## Dependencies

- FastAPI
- SQLite3 (Python built-in)
- Uvicorn
- Requests (for testing)

## License

This feature is part of the WhisperLiveKit project and follows the same license terms. 