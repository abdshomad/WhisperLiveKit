import sqlite3
import os
import logging
from datetime import datetime
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)

class RecordingDatabase:
    def __init__(self, db_path: str = "recordings.db"):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize the database with the recordings table."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS recordings (
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
                    )
                ''')
                conn.commit()
                logger.info("Database initialized successfully")
        except Exception as e:
            logger.error(f"Error initializing database: {e}")
    
    def save_recording(self, filename: str, original_filename: str, title: str = None, 
                      description: str = None, duration: float = None, 
                      file_size: int = None, transcription: str = None) -> int:
        """Save recording details to database."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('''
                    INSERT INTO recordings 
                    (filename, original_filename, title, description, duration, file_size, transcription)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (filename, original_filename, title, description, duration, file_size, transcription))
                conn.commit()
                recording_id = cursor.lastrowid
                logger.info(f"Recording saved with ID: {recording_id}")
                return recording_id
        except Exception as e:
            logger.error(f"Error saving recording: {e}")
            return None
    
    def get_all_recordings(self) -> List[Dict]:
        """Get all recordings from database."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                cursor.execute('''
                    SELECT * FROM recordings ORDER BY created_at DESC
                ''')
                recordings = []
                for row in cursor.fetchall():
                    recordings.append(dict(row))
                return recordings
        except Exception as e:
            logger.error(f"Error getting recordings: {e}")
            return []
    
    def get_recording_by_id(self, recording_id: int) -> Optional[Dict]:
        """Get a specific recording by ID."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                cursor.execute('''
                    SELECT * FROM recordings WHERE id = ?
                ''', (recording_id,))
                row = cursor.fetchone()
                return dict(row) if row else None
        except Exception as e:
            logger.error(f"Error getting recording {recording_id}: {e}")
            return None
    
    def update_recording(self, recording_id: int, **kwargs) -> bool:
        """Update recording details."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Build update query dynamically
                update_fields = []
                values = []
                for key, value in kwargs.items():
                    if key in ['title', 'description', 'transcription']:
                        update_fields.append(f"{key} = ?")
                        values.append(value)
                
                if not update_fields:
                    return False
                
                update_fields.append("updated_at = CURRENT_TIMESTAMP")
                values.append(recording_id)
                
                query = f"UPDATE recordings SET {', '.join(update_fields)} WHERE id = ?"
                cursor.execute(query, values)
                conn.commit()
                
                logger.info(f"Recording {recording_id} updated successfully")
                return True
        except Exception as e:
            logger.error(f"Error updating recording {recording_id}: {e}")
            return False
    
    def delete_recording(self, recording_id: int) -> bool:
        """Delete a recording from database."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('DELETE FROM recordings WHERE id = ?', (recording_id,))
                conn.commit()
                
                if cursor.rowcount > 0:
                    logger.info(f"Recording {recording_id} deleted successfully")
                    return True
                else:
                    logger.warning(f"Recording {recording_id} not found for deletion")
                    return False
        except Exception as e:
            logger.error(f"Error deleting recording {recording_id}: {e}")
            return False 