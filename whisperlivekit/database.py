import sqlite3
import json
import os
from datetime import datetime
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

class RecordingDatabase:
    def __init__(self, db_path: str = "recordings.db"):
        """Initialize the database with the given path."""
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize the database with required tables."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Create recordings table
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS recordings (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        title TEXT NOT NULL,
                        transcript TEXT NOT NULL,
                        duration INTEGER NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        model_info TEXT,
                        language TEXT,
                        diarization_enabled BOOLEAN DEFAULT 0
                    )
                ''')
                
                conn.commit()
                logger.info("Database initialized successfully")
        except Exception as e:
            logger.error(f"Error initializing database: {e}")
            raise
    
    def save_recording(self, title: str, transcript: str, duration: int, 
                      model_info: str = None, language: str = None, 
                      diarization_enabled: bool = False) -> int:
        """Save a new recording to the database."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute('''
                    INSERT INTO recordings (title, transcript, duration, model_info, language, diarization_enabled)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (title, transcript, duration, model_info, language, diarization_enabled))
                
                recording_id = cursor.lastrowid
                conn.commit()
                logger.info(f"Recording saved with ID: {recording_id}")
                return recording_id
        except Exception as e:
            logger.error(f"Error saving recording: {e}")
            raise
    
    def get_all_recordings(self) -> List[Dict]:
        """Get all recordings from the database."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute('''
                    SELECT id, title, transcript, duration, created_at, model_info, language, diarization_enabled
                    FROM recordings
                    ORDER BY created_at DESC
                ''')
                
                recordings = []
                for row in cursor.fetchall():
                    recordings.append({
                        'id': row[0],
                        'title': row[1],
                        'transcript': row[2],
                        'duration': row[3],
                        'created_at': row[4],
                        'model_info': row[5],
                        'language': row[6],
                        'diarization_enabled': bool(row[7])
                    })
                
                return recordings
        except Exception as e:
            logger.error(f"Error getting recordings: {e}")
            raise
    
    def get_recording_by_id(self, recording_id: int) -> Optional[Dict]:
        """Get a specific recording by ID."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute('''
                    SELECT id, title, transcript, duration, created_at, model_info, language, diarization_enabled
                    FROM recordings
                    WHERE id = ?
                ''', (recording_id,))
                
                row = cursor.fetchone()
                if row:
                    return {
                        'id': row[0],
                        'title': row[1],
                        'transcript': row[2],
                        'duration': row[3],
                        'created_at': row[4],
                        'model_info': row[5],
                        'language': row[6],
                        'diarization_enabled': bool(row[7])
                    }
                return None
        except Exception as e:
            logger.error(f"Error getting recording by ID: {e}")
            raise
    
    def delete_recording(self, recording_id: int) -> bool:
        """Delete a recording by ID."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute('DELETE FROM recordings WHERE id = ?', (recording_id,))
                
                if cursor.rowcount > 0:
                    conn.commit()
                    logger.info(f"Recording {recording_id} deleted successfully")
                    return True
                else:
                    logger.warning(f"Recording {recording_id} not found")
                    return False
        except Exception as e:
            logger.error(f"Error deleting recording: {e}")
            raise
    
    def update_recording_title(self, recording_id: int, new_title: str) -> bool:
        """Update the title of a recording."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute('UPDATE recordings SET title = ? WHERE id = ?', (new_title, recording_id))
                
                if cursor.rowcount > 0:
                    conn.commit()
                    logger.info(f"Recording {recording_id} title updated to: {new_title}")
                    return True
                else:
                    logger.warning(f"Recording {recording_id} not found for title update")
                    return False
        except Exception as e:
            logger.error(f"Error updating recording title: {e}")
            raise 