#!/usr/bin/env python3
"""
WhisperLiveKit FastAPI Application
Modern web interface with Jinja templates and GPU-accelerated speech recognition
"""

import os
import sys
import asyncio
import logging
import logging.handlers
from pathlib import Path
from typing import Dict, Any
from contextlib import asynccontextmanager
import time # Added for recording duration tracking
from datetime import datetime # Added for timestamp in log file name

import uvicorn
from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Import WhisperLiveKit components
from whisperlivekit.core import TranscriptionEngine
from whisperlivekit.audio_processor import AudioProcessor

# Setup comprehensive logging
def setup_logging():
    """Setup comprehensive logging for debugging."""
    # Create logs directory if it doesn't exist
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    
    # Use environment variable for log file name if set, otherwise generate timestamp
    if os.getenv("WHISPERLIVEKIT_LOG_FILE"):
        log_file = Path(os.getenv("WHISPERLIVEKIT_LOG_FILE"))
    else:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        log_file = log_dir / f"fastapi_{timestamp}.log"
    
    # Configure root logger
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            # Console handler with INFO level
            logging.StreamHandler(sys.stdout),
            # File handler for all logs (consolidated into main log file)
            logging.handlers.RotatingFileHandler(
                log_file,
                maxBytes=10*1024*1024,  # 10MB
                backupCount=5
            )
        ]
    )
    
    # Set specific loggers to use the same configuration
    loggers_to_configure = [
        'uvicorn',
        'fastapi',
        'websockets',
        'whisperlivekit',
        'whisper_streaming_custom',
        'audio_processor',
        'ffmpeg_manager'
    ]
    
    for logger_name in loggers_to_configure:
        logger = logging.getLogger(logger_name)
        logger.setLevel(logging.DEBUG)
        # Ensure all loggers use the same handlers
        logger.propagate = True
    
    # Create main application logger
    logger = logging.getLogger("whisperlivekit.main")
    logger.info(f"Logging system initialized - All logs consolidated into: {log_file}")
    return logger

# Initialize logging
logger = setup_logging()

# Import argument parsing after logging setup
from whisperlivekit.parse_args import parse_args
args = parse_args()

# Initialize GPU status
def check_gpu_availability() -> Dict[str, Any]:
    """Check GPU availability and return status information."""
    logger.info("Checking GPU availability...")
    
    try:
        import torch
        gpu_info = {
            "cuda_available": torch.cuda.is_available(),
            "cuda_device_count": torch.cuda.device_count() if torch.cuda.is_available() else 0,
            "current_device": torch.cuda.current_device() if torch.cuda.is_available() else None,
            "device_name": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
        }
        
        if gpu_info["cuda_available"]:
            logger.info(f"GPU available: {gpu_info['device_name']}")
            logger.info(f"CUDA device count: {gpu_info['cuda_device_count']}")
            
            # Test CUDA operations
            try:
                test_tensor = torch.tensor([1.0], device='cuda')
                logger.info("CUDA tensor operations working correctly")
            except Exception as e:
                logger.error(f"CUDA tensor operations failed: {e}")
                gpu_info["cuda_available"] = False
                gpu_info["cuda_error"] = str(e)
        else:
            logger.warning("No GPU available. Using CPU for inference.")
            
    except ImportError as e:
        logger.error(f"PyTorch not available: {e}")
        gpu_info = {
            "cuda_available": False,
            "cuda_device_count": 0,
            "current_device": None,
            "device_name": None,
            "error": "PyTorch not installed"
        }
    except Exception as e:
        logger.error(f"Error checking GPU availability: {e}")
        gpu_info = {
            "cuda_available": False,
            "cuda_device_count": 0,
            "current_device": None,
            "device_name": None,
            "error": str(e)
        }
    
    logger.info(f"GPU status: {gpu_info}")
    return gpu_info

gpu_status = check_gpu_availability()
transcription_engine = None

# Setup Jinja2 templates
templates_dir = Path(__file__).parent / "templates"
templates = Jinja2Templates(directory=str(templates_dir))

# Setup static files
static_dir = Path(__file__).parent / "static"
static_dir.mkdir(exist_ok=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    global transcription_engine
    
    logger.info("🚀 STARTING WHISPERLIVEKIT FASTAPI APPLICATION")
    logger.info(f"📊 GPU Status: {gpu_status}")
    
    try:
        # Initialize transcription engine
        logger.info("🔧 INITIALIZING TRANSCRIPTION ENGINE")
        logger.info(f"📋 Configuration:")
        logger.info(f"   - Model: {args.model}")
        logger.info(f"   - Language: {args.lan}")
        logger.info(f"   - Diarization: {args.diarization}")
        logger.info(f"   - Backend: {args.backend}")
        logger.info(f"   - Task: {args.task}")
        logger.info(f"   - Min Chunk Size: {args.min_chunk_size}")
        logger.info(f"   - Warmup File: {args.warmup_file}")
        
        # Set environment variables for CUDA if needed
        if not gpu_status["cuda_available"] and "CUDA_VISIBLE_DEVICES" not in os.environ:
            logger.info("⚠️ Setting CUDA_VISIBLE_DEVICES to empty to force CPU mode")
            os.environ["CUDA_VISIBLE_DEVICES"] = ""
        
        logger.info("🎤 CREATING TRANSCRIPTION ENGINE INSTANCE")
        transcription_engine = TranscriptionEngine(
            model=args.model,
            language=args.lan,
            diarization=args.diarization,
            backend=args.backend,
            task=args.task,
            min_chunk_size=args.min_chunk_size,
            warmup_file=args.warmup_file
        )
        
        logger.info("✅ TRANSCRIPTION ENGINE INITIALIZED SUCCESSFULLY")
        logger.info("🎯 ENGINE READY FOR REAL-TIME TRANSCRIPTION")
        logger.info("📡 WebSocket endpoint available at /ws/asr")
        logger.info("🌐 Web interface available at /")
        
    except Exception as e:
        logger.error(f"❌ FAILED TO INITIALIZE TRANSCRIPTION ENGINE: {e}", exc_info=True)
        transcription_engine = None
        raise
    
    yield
    
    logger.info("🛑 SHUTTING DOWN WHISPERLIVEKIT APPLICATION")
    if transcription_engine:
        try:
            # Cleanup transcription engine if needed
            logger.info("🧹 CLEANING UP TRANSCRIPTION ENGINE")
        except Exception as e:
            logger.error(f"❌ ERROR DURING CLEANUP: {e}", exc_info=True)
    
    logger.info("✅ APPLICATION SHUTDOWN COMPLETE")

# Create FastAPI application
app = FastAPI(
    title="WhisperLiveKit",
    description="Real-time, Fully Local Whisper's Speech-to-Text and Speaker Diarization",
    version="0.2.2",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

# Pydantic models for API
class ServerInfo(BaseModel):
    """Server information model."""
    script_name: str
    model: str
    language: str
    diarization: bool
    backend: str
    task: str
    host: str
    port: int
    gpu_status: Dict[str, Any]

class TranscriptionResponse(BaseModel):
    """Transcription response model."""
    type: str
    text: str = ""
    confidence: float = 0.0
    timestamp: float = 0.0

@app.get("/", response_class=HTMLResponse)
async def get_home(request: Request):
    """Serve the main web interface."""
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "server_info": {
                "model": args.model,
                "language": args.lan,
                "diarization": args.diarization,
                "backend": args.backend,
                "task": args.task,
            },
            "gpu_status": gpu_status,
        }
    )

@app.get("/legacy", response_class=HTMLResponse)
async def get_legacy_interface():
    """Serve the legacy WhisperLiveKit web interface."""
    try:
        from whisperlivekit.web import get_web_interface_html
        html_content = get_web_interface_html()
        return HTMLResponse(content=html_content)
    except Exception as e:
        logger.error(f"Error loading legacy web interface: {e}")
        return HTMLResponse(content="<html><body><h1>Error loading legacy interface</h1></body></html>")

@app.get("/test", response_class=HTMLResponse)
async def get_test(request: Request):
    """Serve the WebSocket test page."""
    with open("tests/test_websocket.html", "r") as f:
        content = f.read()
    return HTMLResponse(content=content)

@app.get("/test-client", response_class=HTMLResponse)
async def get_test_client(request: Request):
    """Serve the client fixes test page."""
    with open("test_client_fixes.html", "r") as f:
        content = f.read()
    return HTMLResponse(content=content)

@app.get("/test-js", response_class=HTMLResponse)
async def get_test_js(request: Request):
    """Serve the JavaScript fixes test page."""
    with open("test_js_fixes.html", "r") as f:
        content = f.read()
    return HTMLResponse(content=content)

@app.get("/test-debug", response_class=HTMLResponse)
async def get_test_debug(request: Request):
    """Serve the debug logging test page."""
    with open("test_debug_logging.html", "r") as f:
        content = f.read()
    return HTMLResponse(content=content)

@app.get("/api/server-info")
async def get_server_info():
    """Return server configuration information."""
    script_name = os.environ.get('CALLING_SCRIPT', 'whisperlivekit-server')
    if script_name and script_name != 'whisperlivekit-server':
        script_name = os.path.basename(script_name)
    
    server_info = ServerInfo(
        script_name=script_name,
        model=args.model,
        language=args.lan,
        diarization=args.diarization,
        backend=args.backend,
        task=args.task,
        host=args.host,
        port=args.port,
        gpu_status=gpu_status,
    )
    
    return server_info

@app.get("/server-info")
async def get_server_info_legacy():
    """Return server configuration information for legacy compatibility."""
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

@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "gpu_available": gpu_status["cuda_available"],
        "transcription_engine_ready": transcription_engine is not None,
    }

@app.get("/api/logs")
async def get_logs(lines: int = 100):
    """Return recent log entries."""
    try:
        # Get the current log file from environment or use the most recent one
        log_file = os.getenv("WHISPERLIVEKIT_LOG_FILE")
        if not log_file or not Path(log_file).exists():
            # Find the most recent log file
            log_dir = Path("logs")
            log_files = list(log_dir.glob("fastapi_*.log"))
            if log_files:
                log_file = str(max(log_files, key=lambda x: x.stat().st_mtime))
            else:
                return {"error": "No log files found"}
        
        with open(log_file, 'r') as f:
            all_lines = f.readlines()
            recent_lines = all_lines[-lines:] if len(all_lines) > lines else all_lines
        
        return {
            "log_file": log_file,
            "total_lines": len(all_lines),
            "recent_lines": recent_lines,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error reading logs: {e}")
        return {"error": f"Failed to read logs: {str(e)}"}

@app.get("/logs", response_class=HTMLResponse)
async def get_logs_page(request: Request):
    """Serve a log viewing page."""
    return templates.TemplateResponse(
        "logs.html",
        {
            "request": request,
            "title": "Application Logs"
        }
    )

async def handle_websocket_results(websocket: WebSocket, results_generator):
    """Consumes results from the audio processor and sends them via WebSocket."""
    logger.info("Starting WebSocket results handler")
    message_count = 0
    
    try:
        async for response in results_generator:
            message_count += 1
            logger.debug(f"Sending message #{message_count}: {response}")
            
            try:
                await websocket.send_json(response)
                logger.debug(f"Successfully sent message #{message_count}")
            except Exception as e:
                logger.error(f"Failed to send message #{message_count}: {e}", exc_info=True)
                break
                
        # When the results_generator finishes, all audio has been processed
        logger.info(f"Results generator finished after {message_count} messages. Sending 'ready_to_stop' to client.")
        await websocket.send_json({"type": "ready_to_stop"})
        
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected while handling results after {message_count} messages.")
    except Exception as e:
        logger.error(f"Error in WebSocket results handler after {message_count} messages: {e}", exc_info=True)

@app.websocket("/ws/asr")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time speech recognition (Enhanced FastAPI version)."""
    global transcription_engine
    
    client_id = f"{websocket.client.host}:{websocket.client.port}" if websocket.client else "unknown"
    logger.info(f"WebSocket connection request from {client_id}")
    
    if transcription_engine is None:
        logger.error(f"Transcription engine not initialized. Rejecting connection from {client_id}")
        await websocket.close(code=1008, reason="Transcription engine not initialized")
        return
    
    try:
        await websocket.accept()
        logger.info(f"WebSocket connection accepted for {client_id}")
        
        # Initialize audio processor
        logger.info(f"Initializing AudioProcessor for {client_id}")
        audio_processor = AudioProcessor(transcription_engine=transcription_engine)
        
        # Create tasks and results generator
        logger.info(f"Creating tasks for {client_id}")
        results_generator = await audio_processor.create_tasks()
        
        # Start WebSocket results handler
        websocket_task = asyncio.create_task(
            handle_websocket_results(websocket, results_generator)
        )
        logger.info(f"WebSocket results handler started for {client_id}")

        # Main message processing loop
        audio_chunk_count = 0
        total_bytes_received = 0
        recording_start_time = None
        
        try:
            while True:
                logger.debug(f"Waiting for audio data from {client_id}")
                message = await websocket.receive_bytes()
                audio_chunk_count += 1
                chunk_size = len(message)
                total_bytes_received += chunk_size
                
                # Track recording start
                if audio_chunk_count == 1:
                    recording_start_time = time.time()
                    logger.info(f"🎤 START RECORDING from {client_id} - First audio chunk received ({chunk_size} bytes)")
                
                logger.info(f"📥 RECEIVED CHUNK #{audio_chunk_count} from {client_id} ({chunk_size} bytes, total: {total_bytes_received} bytes)")
                
                try:
                    # Process the audio chunk
                    logger.debug(f"🔄 PROCESSING CHUNK #{audio_chunk_count} from {client_id}")
                    await audio_processor.process_audio(message)
                    logger.debug(f"✅ Successfully processed audio chunk #{audio_chunk_count} from {client_id}")
                    
                except Exception as e:
                    logger.error(f"❌ Failed to process audio chunk #{audio_chunk_count} from {client_id}: {e}", exc_info=True)
                    
        except KeyError as e:
            if 'bytes' in str(e):
                if recording_start_time:
                    duration = time.time() - recording_start_time
                    logger.info(f"🎤 END RECORDING from {client_id} - Duration: {duration:.2f}s, Chunks: {audio_chunk_count}, Total bytes: {total_bytes_received}")
                else:
                    logger.info(f"Client {client_id} has closed the connection during message receiving.")
            else:
                logger.error(f"Unexpected KeyError in websocket_endpoint for {client_id}: {e}", exc_info=True)
        except WebSocketDisconnect:
            if recording_start_time:
                duration = time.time() - recording_start_time
                logger.info(f"🎤 END RECORDING from {client_id} - Duration: {duration:.2f}s, Chunks: {audio_chunk_count}, Total bytes: {total_bytes_received}")
            else:
                logger.info(f"WebSocket disconnected by client {client_id} during message receiving loop.")
        except Exception as e:
            logger.error(f"Unexpected error in websocket_endpoint main loop for {client_id}: {e}", exc_info=True)
            
    except Exception as e:
        logger.error(f"Error during WebSocket setup for {client_id}: {e}", exc_info=True)
        try:
            await websocket.close(code=1011, reason="Internal server error")
        except:
            pass
        return
        
    finally:
        logger.info(f"Cleaning up WebSocket endpoint for {client_id}...")
        
        # Cancel WebSocket results task
        if not websocket_task.done():
            logger.info(f"Cancelling WebSocket results task for {client_id}")
            websocket_task.cancel()
            try:
                await websocket_task
            except asyncio.CancelledError:
                logger.info(f"WebSocket results handler task was cancelled for {client_id}")
            except Exception as e:
                logger.warning(f"Exception while awaiting websocket_task completion for {client_id}: {e}")
        
        # Cleanup audio processor
        try:
            await audio_processor.cleanup()
            logger.info(f"AudioProcessor cleanup completed for {client_id}")
        except Exception as e:
            logger.error(f"Error during AudioProcessor cleanup for {client_id}: {e}", exc_info=True)
        
        logger.info(f"WebSocket endpoint cleaned up successfully for {client_id}")

@app.websocket("/asr")
async def websocket_endpoint_legacy(websocket: WebSocket):
    """WebSocket endpoint for legacy WhisperLiveKit compatibility."""
    global transcription_engine
    audio_processor = AudioProcessor(
        transcription_engine=transcription_engine,
    )
    await websocket.accept()
    logger.info("WebSocket connection opened (legacy endpoint).")
            
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
        logger.info("Cleaning up WebSocket endpoint...")
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

# Add main execution block for direct running
if __name__ == "__main__":
    import uvicorn
    
    # Set environment variable for the calling script
    os.environ['CALLING_SCRIPT'] = 'main.py'
    
    # Run the FastAPI application
    uvicorn.run(
        "main:app",
        host=args.host,
        port=args.port,
        reload=False,
        log_level="info",
        lifespan="on"
    ) 