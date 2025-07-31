import os
import logging
import asyncio
from datetime import datetime
from typing import Optional, Dict, List
import wave
import json
import subprocess
import tempfile
from pathlib import Path

from .database import RecordingDatabase

logger = logging.getLogger(__name__)

class RecordingManager:
    def __init__(self, recordings_dir: str = "recordings"):
        self.recordings_dir = Path(recordings_dir)
        self.recordings_dir.mkdir(exist_ok=True)
        self.db = RecordingDatabase()
        self.current_recording = None
        self.recording_start_time = None
        self.audio_chunks = []
        self.transcription_buffer = ""
        
    def start_recording(self, session_id: str = None) -> str:
        """Start a new recording session."""
        if self.current_recording:
            logger.warning("Recording already in progress")
            return None
            
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        session_id = session_id or f"session_{timestamp}"
        filename = f"recording_{timestamp}.mp3"  # Changed from .wav to .mp3
        filepath = self.recordings_dir / filename
        
        self.current_recording = {
            "session_id": session_id,
            "filename": filename,
            "filepath": filepath,
            "start_time": datetime.now(),
            "audio_chunks": [],
            "transcription": ""
        }
        
        self.recording_start_time = datetime.now()
        self.audio_chunks = []
        self.transcription_buffer = ""
        
        logger.info(f"Started recording: {filename}")
        return session_id
    
    def add_audio_chunk(self, audio_data: bytes, session_id: str = None):
        """Add audio chunk to current recording."""
        if not self.current_recording:
            logger.warning("No active recording")
            return False
            
        if session_id and self.current_recording["session_id"] != session_id:
            logger.warning(f"Session ID mismatch: {session_id} vs {self.current_recording['session_id']}")
            return False
            
        self.current_recording["audio_chunks"].append(audio_data)
        logger.debug(f"Added audio chunk, total chunks: {len(self.current_recording['audio_chunks'])}")
        return True
    
    def add_processed_audio_chunk(self, processed_audio_data: bytes, session_id: str = None):
        """Add processed audio chunk (PCM s16le format) to current recording."""
        if not self.current_recording:
            logger.warning("No active recording")
            return False
            
        if session_id and self.current_recording["session_id"] != session_id:
            logger.warning(f"Session ID mismatch: {session_id} vs {self.current_recording['session_id']}")
            return False
            
        self.current_recording["audio_chunks"].append(processed_audio_data)
        logger.debug(f"Added processed audio chunk, total chunks: {len(self.current_recording['audio_chunks'])}")
        return True
    
    def add_transcription(self, transcription: str, session_id: str = None):
        """Add transcription text to current recording."""
        if not self.current_recording:
            logger.warning("No active recording")
            return False
            
        if session_id and self.current_recording["session_id"] != session_id:
            logger.warning(f"Session ID mismatch: {session_id} vs {self.current_recording['session_id']}")
            return False
            
        self.current_recording["transcription"] += transcription + " "
        logger.debug(f"Added transcription: {transcription}")
        return True
    
    def stop_recording(self, session_id: str = None) -> Optional[Dict]:
        """Stop current recording and save to file."""
        if not self.current_recording:
            logger.warning("No active recording to stop")
            return None
            
        if session_id and self.current_recording["session_id"] != session_id:
            logger.warning(f"Session ID mismatch: {session_id} vs {self.current_recording['session_id']}")
            return None
        
        try:
            # Calculate duration
            end_time = datetime.now()
            duration = (end_time - self.current_recording["start_time"]).total_seconds()
            
            # Save audio file
            filepath = self.current_recording["filepath"]
            self._save_audio_file(filepath, self.current_recording["audio_chunks"])
            
            # Get file size
            file_size = filepath.stat().st_size if filepath.exists() else 0
            
            # Save to database
            recording_id = self.db.save_recording(
                filename=self.current_recording["filename"],
                original_filename=self.current_recording["filename"],
                title=f"Recording {self.current_recording['start_time'].strftime('%Y-%m-%d %H:%M:%S')}",
                description=f"Session: {self.current_recording['session_id']}",
                duration=duration,
                file_size=file_size,
                transcription=self.current_recording["transcription"].strip()
            )
            
            recording_info = {
                "id": recording_id,
                "filename": self.current_recording["filename"],
                "title": f"Recording {self.current_recording['start_time'].strftime('%Y-%m-%d %H:%M:%S')}",
                "duration": duration,
                "file_size": file_size,
                "transcription": self.current_recording["transcription"].strip(),
                "created_at": self.current_recording["start_time"].isoformat()
            }
            
            logger.info(f"Recording stopped and saved: {self.current_recording['filename']}")
            
            # Clear current recording
            self.current_recording = None
            self.recording_start_time = None
            self.audio_chunks = []
            self.transcription_buffer = ""
            
            return recording_info
            
        except Exception as e:
            logger.error(f"Error stopping recording: {e}")
            return None
    
    def _save_audio_file(self, filepath: Path, audio_chunks: List[bytes]):
        """Save processed audio chunks (PCM s16le format) to MP3 file using FFmpeg."""
        try:
            if not audio_chunks:
                logger.warning("No audio chunks to save")
                # Create an empty MP3 file
                with open(filepath, 'wb') as f:
                    # Write minimal MP3 header (silent MP3)
                    f.write(b'\xff\xfb\x90\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
                return
            
            # Calculate total size of audio data
            total_size = sum(len(chunk) for chunk in audio_chunks)
            
            # Create a temporary WAV file for FFmpeg input
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_wav:
                temp_wav_path = temp_wav.name
                
                # Write WAV header to temporary file
                temp_wav.write(b'RIFF')
                temp_wav.write((36 + total_size).to_bytes(4, 'little'))  # File size - 8
                temp_wav.write(b'WAVE')
                temp_wav.write(b'fmt ')
                temp_wav.write((16).to_bytes(4, 'little'))  # fmt chunk size
                temp_wav.write((1).to_bytes(2, 'little'))   # PCM format
                temp_wav.write((1).to_bytes(2, 'little'))   # Mono
                temp_wav.write((16000).to_bytes(4, 'little'))  # Sample rate
                temp_wav.write((32000).to_bytes(4, 'little'))  # Byte rate
                temp_wav.write((2).to_bytes(2, 'little'))   # Block align
                temp_wav.write((16).to_bytes(2, 'little'))  # Bits per sample
                temp_wav.write(b'data')
                temp_wav.write(total_size.to_bytes(4, 'little'))  # Data size
                
                # Write processed PCM audio data to temporary file
                for chunk in audio_chunks:
                    temp_wav.write(chunk)
            
            try:
                # Use FFmpeg to convert WAV to MP3
                cmd = [
                    'ffmpeg',
                    '-y',  # Overwrite output file
                    '-f', 'wav',
                    '-i', temp_wav_path,
                    '-acodec', 'libmp3lame',
                    '-ab', '128k',  # 128 kbps bitrate
                    '-ar', '16000',  # 16kHz sample rate
                    '-ac', '1',      # Mono
                    str(filepath)
                ]
                
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=30  # 30 second timeout
                )
                
                if result.returncode != 0:
                    logger.error(f"FFmpeg conversion failed: {result.stderr}")
                    # Fallback: save as WAV if MP3 conversion fails
                    filepath = filepath.with_suffix('.wav')
                    with open(filepath, 'wb') as f:
                        f.write(b'RIFF')
                        f.write((36 + total_size).to_bytes(4, 'little'))
                        f.write(b'WAVE')
                        f.write(b'fmt ')
                        f.write((16).to_bytes(4, 'little'))
                        f.write((1).to_bytes(2, 'little'))
                        f.write((1).to_bytes(2, 'little'))
                        f.write((16000).to_bytes(4, 'little'))
                        f.write((32000).to_bytes(4, 'little'))
                        f.write((2).to_bytes(2, 'little'))
                        f.write((16).to_bytes(2, 'little'))
                        f.write(b'data')
                        f.write(total_size.to_bytes(4, 'little'))
                        for chunk in audio_chunks:
                            f.write(chunk)
                    logger.info(f"Audio file saved as WAV (fallback): {filepath}")
                else:
                    logger.info(f"Audio file saved as MP3: {filepath}")
                    
            finally:
                # Clean up temporary WAV file
                try:
                    os.unlink(temp_wav_path)
                except OSError:
                    pass
                    
        except Exception as e:
            logger.error(f"Error saving audio file: {e}")
            raise
    
    def get_all_recordings(self) -> List[Dict]:
        """Get all recordings from database."""
        return self.db.get_all_recordings()
    
    def get_recording(self, recording_id: int) -> Optional[Dict]:
        """Get a specific recording by ID."""
        return self.db.get_recording_by_id(recording_id)
    
    def update_recording(self, recording_id: int, **kwargs) -> bool:
        """Update recording details."""
        return self.db.update_recording(recording_id, **kwargs)
    
    def delete_recording(self, recording_id: int) -> bool:
        """Delete a recording."""
        recording = self.db.get_recording_by_id(recording_id)
        if recording:
            # Delete file
            filepath = self.recordings_dir / recording["filename"]
            if filepath.exists():
                filepath.unlink()
                logger.info(f"Deleted file: {filepath}")
            
            # Delete from database
            return self.db.delete_recording(recording_id)
        return False
    
    def get_recording_file_path(self, recording_id: int) -> Optional[Path]:
        """Get the file path for a recording."""
        recording = self.db.get_recording_by_id(recording_id)
        if recording:
            filepath = self.recordings_dir / recording["filename"]
            if filepath.exists():
                return filepath
        return None
    
    def is_recording(self) -> bool:
        """Check if currently recording."""
        return self.current_recording is not None
    
    def get_current_recording_info(self) -> Optional[Dict]:
        """Get info about current recording."""
        if not self.current_recording:
            return None
            
        duration = (datetime.now() - self.current_recording["start_time"]).total_seconds()
        return {
            "session_id": self.current_recording["session_id"],
            "filename": self.current_recording["filename"],
            "duration": duration,
            "chunks_count": len(self.current_recording["audio_chunks"]),
            "transcription_length": len(self.current_recording["transcription"])
        } 