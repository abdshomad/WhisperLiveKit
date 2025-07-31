from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from whisperlivekit import TranscriptionEngine, AudioProcessor, get_web_interface_html, parse_args
from whisperlivekit.database import RecordingDatabase
import asyncio
import logging
import os
import json
from datetime import datetime

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logging.getLogger().setLevel(logging.WARNING)
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

args = parse_args()
transcription_engine = None
recording_db = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global transcription_engine, recording_db
    transcription_engine = TranscriptionEngine(
        **vars(args),
    )
    recording_db = RecordingDatabase()
    yield

app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def get():
    return HTMLResponse(get_web_interface_html())

@app.get("/server-info")
async def get_server_info():
    """Return server configuration information for the web interface."""
    script_name = os.environ.get('CALLING_SCRIPT', 'whisperlivekit-server')
    if script_name and script_name != 'whisperlivekit-server':
        script_name = os.path.basename(script_name)
    
    server_info = {
        "script_name": script_name,
        "model": args.model,
        "language": args.lan,
        "diarization": args.diarization,
        "backend": args.backend,
        "task": args.task,
        "host": args.host,
        "port": args.port,
    }
    
    return JSONResponse(server_info)

@app.post("/api/recordings")
async def save_recording(request: dict):
    """Save a new recording to the database."""
    try:
        title = request.get("title", "Untitled Recording")
        transcript = request.get("transcript", "")
        duration = request.get("duration", 0)
        model_info = request.get("model_info", args.model)
        language = request.get("language", args.lan)
        diarization_enabled = request.get("diarization_enabled", args.diarization)
        
        recording_id = recording_db.save_recording(
            title=title,
            transcript=transcript,
            duration=duration,
            model_info=model_info,
            language=language,
            diarization_enabled=diarization_enabled
        )
        
        return JSONResponse({
            "success": True,
            "recording_id": recording_id,
            "message": "Recording saved successfully"
        })
    except Exception as e:
        logger.error(f"Error saving recording: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/recordings")
async def get_recordings():
    """Get all recordings from the database."""
    try:
        recordings = recording_db.get_all_recordings()
        return JSONResponse({
            "success": True,
            "recordings": recordings
        })
    except Exception as e:
        logger.error(f"Error getting recordings: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/recordings/{recording_id}")
async def get_recording(recording_id: int):
    """Get a specific recording by ID."""
    try:
        recording = recording_db.get_recording_by_id(recording_id)
        if recording:
            return JSONResponse({
                "success": True,
                "recording": recording
            })
        else:
            raise HTTPException(status_code=404, detail="Recording not found")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting recording: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/recordings/{recording_id}")
async def delete_recording(recording_id: int):
    """Delete a recording by ID."""
    try:
        success = recording_db.delete_recording(recording_id)
        if success:
            return JSONResponse({
                "success": True,
                "message": "Recording deleted successfully"
            })
        else:
            raise HTTPException(status_code=404, detail="Recording not found")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting recording: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/recordings/{recording_id}/title")
async def update_recording_title(recording_id: int, request: dict):
    """Update the title of a recording."""
    try:
        new_title = request.get("title")
        if not new_title:
            raise HTTPException(status_code=400, detail="Title is required")
        
        success = recording_db.update_recording_title(recording_id, new_title)
        if success:
            return JSONResponse({
                "success": True,
                "message": "Title updated successfully"
            })
        else:
            raise HTTPException(status_code=404, detail="Recording not found")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating recording title: {e}")
        raise HTTPException(status_code=500, detail=str(e))

async def handle_websocket_results(websocket, results_generator):
    """Consumes results from the audio processor and sends them via WebSocket."""
    try:
        async for response in results_generator:
            await websocket.send_json(response)
        logger.info("Results generator finished. Sending 'ready_to_stop' to client.")
        await websocket.send_json({"type": "ready_to_stop"})
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected while handling results (client likely closed connection).")
    except Exception as e:
        logger.warning(f"Error in WebSocket results handler: {e}")

@app.websocket("/asr")
async def websocket_endpoint(websocket: WebSocket):
    global transcription_engine
    audio_processor = AudioProcessor(
        transcription_engine=transcription_engine,
    )
    await websocket.accept()
    logger.info("WebSocket connection opened.")
            
    results_generator = await audio_processor.create_tasks()
    websocket_task = asyncio.create_task(handle_websocket_results(websocket, results_generator))

    try:
        while True:
            message = await websocket.receive_bytes()
            await audio_processor.process_audio(message)
    except KeyError as e:
        if 'bytes' in str(e):
            logger.warning(f"Client has closed the connection.")
        else:
            logger.error(f"Unexpected KeyError in websocket_endpoint: {e}", exc_info=True)
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected by client during message receiving loop.")
    except Exception as e:
        logger.error(f"Unexpected error in websocket_endpoint main loop: {e}", exc_info=True)
    finally:
        if not websocket_task.done():
            websocket_task.cancel()
            try:
                await websocket_task
            except asyncio.CancelledError:
                pass

def main():
    import uvicorn
    # Override the port to 9002 for testing
    uvicorn.run(
        "whisperlivekit.server_with_recordings:app",
        host=args.host,
        port=9002,  # Use port 9002 as requested
        reload=False,
        log_level="info"
    )

if __name__ == "__main__":
    main() 