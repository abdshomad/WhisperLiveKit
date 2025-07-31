from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from whisperlivekit import TranscriptionEngine, AudioProcessor, parse_args
from whisperlivekit.web.web_interface_enhanced_https import get_web_interface_html
from whisperlivekit.database import RecordingDatabase
from whisperlivekit.enhanced_logging import get_logger
from whisperlivekit.version_info import get_version_info
import asyncio
import time
import os
import json
from datetime import datetime

# Initialize enhanced logger
logger = get_logger()
version_info = get_version_info()

args = parse_args()
transcription_engine = None
recording_db = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global transcription_engine, recording_db
    
    logger.info("=== SERVER STARTUP ===")
    logger.info(f"Version: {version_info.get_version_string()}")
    logger.info(f"Arguments: {vars(args)}")
    
    try:
        logger.info("Initializing transcription engine...")
        transcription_engine = TranscriptionEngine(**vars(args))
        logger.info("Transcription engine initialized successfully")
    except Exception as e:
        logger.log_error_with_context(e, "TranscriptionEngine initialization")
        raise
    
    try:
        logger.info("Initializing database...")
        recording_db = RecordingDatabase()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.log_error_with_context(e, "Database initialization")
        raise
    
    logger.info("=== SERVER READY ===")
    yield
    
    logger.info("=== SERVER SHUTDOWN ===")

app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all HTTP requests with performance metrics."""
    start_time = time.time()
    
    # Log request
    logger.info(f"REQUEST: {request.method} {request.url.path} | Client: {request.client.host if request.client else 'unknown'}")
    
    try:
        response = await call_next(request)
        duration_ms = (time.time() - start_time) * 1000
        
        # Log response
        logger.log_api_request(
            method=request.method,
            endpoint=str(request.url.path),
            status_code=response.status_code,
            duration_ms=duration_ms,
            details={
                "client_ip": request.client.host if request.client else "unknown",
                "user_agent": request.headers.get("user-agent", "unknown")
            }
        )
        
        return response
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        logger.log_error_with_context(e, f"HTTP {request.method} {request.url.path}")
        raise

@app.get("/")
async def get():
    logger.info("Serving main interface")
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
        "version_info": version_info.get_footer_info()
    }
    
    logger.info(f"Serving server info: {json.dumps(server_info, indent=2)}")
    return JSONResponse(server_info)

@app.get("/version")
async def get_version():
    """Get detailed version information."""
    version_data = version_info.get_version_dict()
    logger.info(f"Serving version info: {json.dumps(version_data, indent=2)}")
    return JSONResponse(version_data)

@app.post("/api/recordings")
async def save_recording(request: dict):
    """Save a new recording to the database."""
    start_time = time.time()
    
    try:
        title = request.get("title", "Untitled Recording")
        transcript = request.get("transcript", "")
        duration = request.get("duration", 0)
        model_info = request.get("model_info", args.model)
        language = request.get("language", args.lan)
        diarization_enabled = request.get("diarization_enabled", args.diarization)
        
        logger.log_recording_event("SAVE_ATTEMPT", details={
            "title": title,
            "duration": duration,
            "transcript_length": len(transcript),
            "model_info": model_info,
            "language": language,
            "diarization_enabled": diarization_enabled
        })
        
        recording_id = recording_db.save_recording(
            title=title,
            transcript=transcript,
            duration=duration,
            model_info=model_info,
            language=language,
            diarization_enabled=diarization_enabled
        )
        
        duration_ms = (time.time() - start_time) * 1000
        logger.log_recording_event("SAVE_SUCCESS", recording_id, {
            "duration_ms": duration_ms,
            "transcript_length": len(transcript)
        })
        
        return JSONResponse({
            "success": True,
            "recording_id": recording_id,
            "message": "Recording saved successfully"
        })
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        logger.log_error_with_context(e, "save_recording", {
            "duration_ms": duration_ms,
            "request_data": request
        })
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/recordings")
async def get_recordings():
    """Get all recordings from the database."""
    start_time = time.time()
    
    try:
        recordings = recording_db.get_all_recordings()
        duration_ms = (time.time() - start_time) * 1000
        
        logger.log_recording_event("LIST_SUCCESS", details={
            "count": len(recordings),
            "duration_ms": duration_ms
        })
        
        return JSONResponse({
            "success": True,
            "recordings": recordings
        })
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        logger.log_error_with_context(e, "get_recordings", {"duration_ms": duration_ms})
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/recordings/{recording_id}")
async def get_recording(recording_id: int):
    """Get a specific recording by ID."""
    start_time = time.time()
    
    try:
        recording = recording_db.get_recording_by_id(recording_id)
        duration_ms = (time.time() - start_time) * 1000
        
        if recording:
            logger.log_recording_event("GET_SUCCESS", recording_id, {
                "duration_ms": duration_ms,
                "transcript_length": len(recording.get("transcript", ""))
            })
            return JSONResponse({
                "success": True,
                "recording": recording
            })
        else:
            logger.log_recording_event("GET_NOT_FOUND", recording_id, {"duration_ms": duration_ms})
            raise HTTPException(status_code=404, detail="Recording not found")
    except HTTPException:
        raise
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        logger.log_error_with_context(e, f"get_recording({recording_id})", {"duration_ms": duration_ms})
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/recordings/{recording_id}")
async def delete_recording(recording_id: int):
    """Delete a recording by ID."""
    start_time = time.time()
    
    try:
        success = recording_db.delete_recording(recording_id)
        duration_ms = (time.time() - start_time) * 1000
        
        if success:
            logger.log_recording_event("DELETE_SUCCESS", recording_id, {"duration_ms": duration_ms})
            return JSONResponse({
                "success": True,
                "message": "Recording deleted successfully"
            })
        else:
            logger.log_recording_event("DELETE_NOT_FOUND", recording_id, {"duration_ms": duration_ms})
            raise HTTPException(status_code=404, detail="Recording not found")
    except HTTPException:
        raise
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        logger.log_error_with_context(e, f"delete_recording({recording_id})", {"duration_ms": duration_ms})
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/recordings/{recording_id}/title")
async def update_recording_title(recording_id: int, request: dict):
    """Update the title of a recording."""
    start_time = time.time()
    
    try:
        new_title = request.get("title")
        if not new_title:
            raise HTTPException(status_code=400, detail="Title is required")
        
        success = recording_db.update_recording_title(recording_id, new_title)
        duration_ms = (time.time() - start_time) * 1000
        
        if success:
            logger.log_recording_event("UPDATE_TITLE_SUCCESS", recording_id, {
                "new_title": new_title,
                "duration_ms": duration_ms
            })
            return JSONResponse({
                "success": True,
                "message": "Title updated successfully"
            })
        else:
            logger.log_recording_event("UPDATE_TITLE_NOT_FOUND", recording_id, {
                "new_title": new_title,
                "duration_ms": duration_ms
            })
            raise HTTPException(status_code=404, detail="Recording not found")
    except HTTPException:
        raise
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        logger.log_error_with_context(e, f"update_recording_title({recording_id})", {
            "duration_ms": duration_ms,
            "new_title": request.get("title")
        })
        raise HTTPException(status_code=500, detail=str(e))

async def handle_websocket_results(websocket, results_generator):
    """Consumes results from the audio processor and sends them via WebSocket."""
    try:
        logger.log_websocket_event("RESULTS_START", {"websocket_id": id(websocket)})
        
        async for response in results_generator:
            await websocket.send_json(response)
        
        logger.log_websocket_event("RESULTS_FINISHED", {"websocket_id": id(websocket)})
        await websocket.send_json({"type": "ready_to_stop"})
    except WebSocketDisconnect:
        logger.log_websocket_event("DISCONNECT", {"websocket_id": id(websocket), "reason": "client_disconnect"})
    except Exception as e:
        logger.log_error_with_context(e, "handle_websocket_results", {"websocket_id": id(websocket)})

@app.websocket("/asr")
async def websocket_endpoint(websocket: WebSocket):
    global transcription_engine
    
    try:
        await websocket.accept()
        logger.log_websocket_event("CONNECT", {
            "websocket_id": id(websocket),
            "client": websocket.client.host if websocket.client else "unknown"
        })
        
        audio_processor = AudioProcessor(transcription_engine=transcription_engine)
        results_generator = await audio_processor.create_tasks()
        
        websocket_task = asyncio.create_task(
            handle_websocket_results(websocket, results_generator)
        )

        try:
            chunk_count = 0
            while True:
                message = await websocket.receive_bytes()
                chunk_count += 1
                
                logger.log_transcription_event("CHUNK_RECEIVED", chunk_count, {
                    "size_bytes": len(message),
                    "websocket_id": id(websocket)
                })
                
                await audio_processor.process_audio(message)
                
        except WebSocketDisconnect:
            logger.log_websocket_event("DISCONNECT", {
                "websocket_id": id(websocket),
                "chunks_processed": chunk_count,
                "reason": "client_disconnect"
            })
        except Exception as e:
            logger.log_error_with_context(e, "websocket_main_loop", {
                "websocket_id": id(websocket),
                "chunks_processed": chunk_count
            })
        finally:
            if not websocket_task.done():
                websocket_task.cancel()
                try:
                    await websocket_task
                except asyncio.CancelledError:
                    pass
                    
    except Exception as e:
        logger.log_error_with_context(e, "websocket_endpoint", {"websocket_id": id(websocket)})

def main():
    import uvicorn
    
    logger.info("=== STARTING ENHANCED HTTPS SERVER ===")
    logger.info(f"Version: {version_info.get_version_string()}")
    logger.info(f"Port: {args.port}")
    logger.info(f"Model: {args.model}")
    logger.info(f"Backend: {args.backend}")
    logger.info("SSL: Enabled with custom certificates")
    
    # Log memory usage at startup
    logger.log_memory_usage()
    logger.log_gpu_memory()
    
    # SSL certificate paths
    ssl_keyfile = "ssl/key.pem"
    ssl_certfile = "ssl/cert.pem"
    
    # Check if SSL certificates exist
    if not os.path.exists(ssl_keyfile) or not os.path.exists(ssl_certfile):
        logger.error(f"SSL certificates not found: {ssl_keyfile}, {ssl_certfile}")
        logger.info("Please generate SSL certificates first")
        return
    
    uvicorn.run(
        "whisperlivekit.server_with_recordings_enhanced_https:app",
        host=args.host,
        port=args.port,
        reload=False,
        log_level="info",
        ssl_keyfile=ssl_keyfile,
        ssl_certfile=ssl_certfile
    )

if __name__ == "__main__":
    main() 