from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Request
from fastapi.responses import HTMLResponse, FileResponse, JSONResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from whisperlivekit import TranscriptionEngine, AudioProcessor, get_web_interface_html, parse_args
from whisperlivekit.recording_manager import RecordingManager
import asyncio
import logging
import os
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logging.getLogger().setLevel(logging.WARNING)
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

args = parse_args()
transcription_engine = None
recording_manager = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global transcription_engine, recording_manager
    transcription_engine = TranscriptionEngine(
        **vars(args),
    )
    recording_manager = RecordingManager()
    yield

app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount recordings directory for file access
recordings_path = Path("recordings")
recordings_path.mkdir(exist_ok=True)
app.mount("/recordings", StaticFiles(directory="recordings"), name="recordings")

@app.get("/")
async def get():
    return HTMLResponse(get_web_interface_html())

# Recording management endpoints
@app.get("/api/recordings")
async def get_recordings():
    """Get all recordings."""
    recordings = recording_manager.get_all_recordings()
    return JSONResponse(content=recordings)

@app.get("/api/recordings/status")
async def get_recording_status():
    """Get current recording status."""
    is_recording = recording_manager.is_recording()
    current_info = recording_manager.get_current_recording_info()
    
    return JSONResponse(content={
        "is_recording": is_recording,
        "current_recording": current_info
    })

@app.post("/api/recordings/start")
async def start_recording(data: dict = None):
    """Start a new recording."""
    session_id = None
    if data and "session_id" in data:
        session_id = data["session_id"]
    
    session_id = recording_manager.start_recording(session_id)
    if not session_id:
        raise HTTPException(status_code=400, detail="Recording already in progress")
    
    return JSONResponse(content={"session_id": session_id, "message": "Recording started"})

@app.post("/api/recordings/stop")
async def stop_recording(data: dict = None):
    """Stop current recording."""
    session_id = None
    if data and "session_id" in data:
        session_id = data["session_id"]
    
    recording_info = recording_manager.stop_recording(session_id)
    if not recording_info:
        raise HTTPException(status_code=400, detail="No active recording to stop")
    
    return JSONResponse(content=recording_info)

@app.get("/api/recordings/{recording_id}")
async def get_recording(recording_id: int):
    """Get a specific recording."""
    recording = recording_manager.get_recording(recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")
    return JSONResponse(content=recording)

@app.get("/api/recordings/{recording_id}/download")
async def download_recording(recording_id: int, request: Request):
    """Download a recording file."""
    filepath = recording_manager.get_recording_file_path(recording_id)
    if not filepath or not filepath.exists():
        raise HTTPException(status_code=404, detail="Recording file not found")
    
    # Check if file is empty
    file_size = filepath.stat().st_size
    if file_size == 0:
        raise HTTPException(status_code=404, detail="Recording file is empty")
    
    # Handle range requests for audio streaming
    range_header = request.headers.get("range")
    if range_header:
        try:
            # Parse range header (e.g., "bytes=0-1023")
            range_str = range_header.replace("bytes=", "")
            start, end = range_str.split("-")
            start_byte = int(start)
            end_byte = int(end) if end else file_size - 1
            
            if start_byte >= file_size or end_byte >= file_size:
                raise HTTPException(status_code=416, detail="Range Not Satisfiable")
            
            # Read the requested range
            with open(filepath, 'rb') as f:
                f.seek(start_byte)
                data = f.read(end_byte - start_byte + 1)
            
            headers = {
                "Content-Range": f"bytes {start_byte}-{end_byte}/{file_size}",
                "Accept-Ranges": "bytes",
                "Content-Length": str(len(data))
            }
            
            return Response(
                content=data,
                headers=headers,
                media_type="audio/wav",
                status_code=206
            )
        except (ValueError, IndexError):
            raise HTTPException(status_code=416, detail="Range Not Satisfiable")
    
    # Return full file
    return FileResponse(
        path=str(filepath),
        filename=filepath.name,
        media_type="audio/wav",
        headers={"Accept-Ranges": "bytes"}
    )

@app.put("/api/recordings/{recording_id}")
async def update_recording(recording_id: int, data: dict):
    """Update recording details."""
    success = recording_manager.update_recording(recording_id, **data)
    if not success:
        raise HTTPException(status_code=404, detail="Recording not found")
    return JSONResponse(content={"message": "Recording updated successfully"})

@app.delete("/api/recordings/{recording_id}")
async def delete_recording(recording_id: int):
    """Delete a recording."""
    success = recording_manager.delete_recording(recording_id)
    if not success:
        raise HTTPException(status_code=404, detail="Recording not found")
    return JSONResponse(content={"message": "Recording deleted successfully"})

async def handle_websocket_results(websocket, results_generator):
    """Consumes results from the audio processor and sends them via WebSocket."""
    try:
        async for response in results_generator:
            # If recording is active, add transcription to recording
            if recording_manager.is_recording():
                if "buffer_transcription" in response and response["buffer_transcription"]:
                    recording_manager.add_transcription(response["buffer_transcription"])
            
            await websocket.send_json(response)
        # when the results_generator finishes it means all audio has been processed
        logger.info("Results generator finished. Sending 'ready_to_stop' to client.")
        await websocket.send_json({"type": "ready_to_stop"})
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected while handling results (client likely closed connection).")
    except Exception as e:
        logger.warning(f"Error in WebSocket results handler: {e}")

@app.websocket("/asr")
async def websocket_endpoint(websocket: WebSocket):
    global transcription_engine, recording_manager
    audio_processor = AudioProcessor(
        transcription_engine=transcription_engine,
    )
    await websocket.accept()
    logger.info("WebSocket connection opened.")
    
    # Start recording automatically when WebSocket connects
    session_id = recording_manager.start_recording()
    logger.info(f"Started recording session: {session_id}")
            
    results_generator = await audio_processor.create_tasks()
    websocket_task = asyncio.create_task(handle_websocket_results(websocket, results_generator))

    try:
        while True:
            message = await websocket.receive_bytes()
            
            # Add audio chunk to recording
            if recording_manager.is_recording():
                recording_manager.add_audio_chunk(message, session_id)
            
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
        logger.info("Cleaning up WebSocket endpoint...")
        
        # Stop recording
        if recording_manager.is_recording():
            recording_info = recording_manager.stop_recording(session_id)
            if recording_info:
                logger.info(f"Recording stopped: {recording_info['filename']}")
        
        if not websocket_task.done():
            websocket_task.cancel()
        try:
            await websocket_task
        except asyncio.CancelledError:
            logger.info("WebSocket results handler task was cancelled.")
        except Exception as e:
            logger.warning(f"Exception while awaiting websocket_task completion: {e}")
            
        await audio_processor.cleanup()
        logger.info("WebSocket endpoint cleaned up successfully.")

def main():
    """Entry point for the CLI command."""
    import uvicorn
    
    uvicorn_kwargs = {
        "app": "whisperlivekit.basic_server:app",
        "host":args.host, 
        "port":args.port, 
        "reload": False,
        "log_level": "info",
        "lifespan": "on",
    }
    
    ssl_kwargs = {}
    if args.ssl_certfile or args.ssl_keyfile:
        if not (args.ssl_certfile and args.ssl_keyfile):
            raise ValueError("Both --ssl-certfile and --ssl-keyfile must be specified together.")
        ssl_kwargs = {
            "ssl_certfile": args.ssl_certfile,
            "ssl_keyfile": args.ssl_keyfile
        }

    if ssl_kwargs:
        uvicorn_kwargs = {**uvicorn_kwargs, **ssl_kwargs}

    uvicorn.run(**uvicorn_kwargs)

if __name__ == "__main__":
    main()
