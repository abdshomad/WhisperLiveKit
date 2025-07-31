import logging
import sys
import os
import json
import time
from datetime import datetime
from typing import Dict, Any, Optional
import traceback

class EnhancedLogger:
    """Enhanced logging system with comprehensive debugging capabilities."""
    
    def __init__(self, name: str = "whisperlivekit", log_level: str = "INFO"):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(getattr(logging, log_level.upper()))
        
        # Create logs directory if it doesn't exist
        os.makedirs("logs", exist_ok=True)
        
        # Create timestamp for log file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_filename = f"logs/whisperlivekit_{timestamp}.log"
        
        # File handler with detailed formatting
        file_handler = logging.FileHandler(log_filename)
        file_formatter = logging.Formatter(
            '%(asctime)s | %(levelname)s | %(name)s | %(funcName)s:%(lineno)d | %(message)s'
        )
        file_handler.setFormatter(file_formatter)
        self.logger.addHandler(file_handler)
        
        # Console handler with color coding
        console_handler = logging.StreamHandler(sys.stdout)
        console_formatter = logging.Formatter(
            '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s'
        )
        console_handler.setFormatter(console_formatter)
        self.logger.addHandler(console_handler)
        
        self.log_filename = log_filename
        self.start_time = time.time()
        
        # Log system information
        self.log_system_info()
    
    def log_system_info(self):
        """Log comprehensive system information."""
        self.info("=== SYSTEM INFORMATION ===")
        self.info(f"Python Version: {sys.version}")
        self.info(f"Platform: {sys.platform}")
        self.info(f"Working Directory: {os.getcwd()}")
        self.info(f"Log File: {self.log_filename}")
        self.info(f"Start Time: {datetime.now().isoformat()}")
        
        # GPU information
        try:
            import torch
            self.info(f"PyTorch Version: {torch.__version__}")
            self.info(f"CUDA Available: {torch.cuda.is_available()}")
            if torch.cuda.is_available():
                self.info(f"CUDA Version: {torch.version.cuda}")
                self.info(f"GPU Count: {torch.cuda.device_count()}")
                for i in range(torch.cuda.device_count()):
                    self.info(f"GPU {i}: {torch.cuda.get_device_name(i)}")
        except ImportError:
            self.info("PyTorch not available")
        except Exception as e:
            self.info(f"Error getting GPU info: {e}")
        
        # Environment variables
        env_vars = ["CUDA_VISIBLE_DEVICES", "CT2_CUDA_DEVICES", "PATH"]
        for var in env_vars:
            value = os.environ.get(var, "Not set")
            self.info(f"Environment {var}: {value}")
        
        self.info("=== END SYSTEM INFORMATION ===")
    
    def log_websocket_event(self, event_type: str, details: Dict[str, Any]):
        """Log WebSocket events with detailed information."""
        self.info(f"WEBSOCKET {event_type.upper()}: {json.dumps(details, indent=2)}")
    
    def log_recording_event(self, event_type: str, recording_id: Optional[int] = None, details: Dict[str, Any] = None):
        """Log recording-related events."""
        details_str = f" | Details: {json.dumps(details, indent=2)}" if details else ""
        id_str = f" | ID: {recording_id}" if recording_id else ""
        self.info(f"RECORDING {event_type.upper()}{id_str}{details_str}")
    
    def log_api_request(self, method: str, endpoint: str, status_code: int, duration_ms: float, details: Dict[str, Any] = None):
        """Log API requests with performance metrics."""
        details_str = f" | Details: {json.dumps(details, indent=2)}" if details else ""
        self.info(f"API {method} {endpoint} | Status: {status_code} | Duration: {duration_ms:.2f}ms{details_str}")
    
    def log_transcription_event(self, event_type: str, chunk_id: Optional[int] = None, details: Dict[str, Any] = None):
        """Log transcription-related events."""
        details_str = f" | Details: {json.dumps(details, indent=2)}" if details else ""
        chunk_str = f" | Chunk: {chunk_id}" if chunk_id else ""
        self.info(f"TRANSCRIPTION {event_type.upper()}{chunk_str}{details_str}")
    
    def log_error_with_context(self, error: Exception, context: str = "", additional_info: Dict[str, Any] = None):
        """Log errors with full context and stack trace."""
        error_info = {
            "error_type": type(error).__name__,
            "error_message": str(error),
            "context": context,
            "stack_trace": traceback.format_exc(),
            "additional_info": additional_info or {}
        }
        self.error(f"ERROR in {context}: {json.dumps(error_info, indent=2)}")
    
    def log_performance_metric(self, metric_name: str, value: float, unit: str = "ms"):
        """Log performance metrics."""
        self.info(f"PERFORMANCE {metric_name}: {value:.2f}{unit}")
    
    def log_memory_usage(self):
        """Log current memory usage."""
        try:
            import psutil
            process = psutil.Process()
            memory_info = process.memory_info()
            self.info(f"MEMORY USAGE: RSS: {memory_info.rss / 1024 / 1024:.2f}MB, VMS: {memory_info.vms / 1024 / 1024:.2f}MB")
        except ImportError:
            self.info("psutil not available for memory monitoring")
        except Exception as e:
            self.info(f"Error getting memory usage: {e}")
    
    def log_gpu_memory(self):
        """Log GPU memory usage if available."""
        try:
            import torch
            if torch.cuda.is_available():
                for i in range(torch.cuda.device_count()):
                    allocated = torch.cuda.memory_allocated(i) / 1024 / 1024
                    cached = torch.cuda.memory_reserved(i) / 1024 / 1024
                    self.info(f"GPU {i} MEMORY: Allocated: {allocated:.2f}MB, Cached: {cached:.2f}MB")
        except Exception as e:
            self.info(f"Error getting GPU memory: {e}")
    
    def debug(self, message: str):
        self.logger.debug(message)
    
    def info(self, message: str):
        self.logger.info(message)
    
    def warning(self, message: str):
        self.logger.warning(message)
    
    def error(self, message: str):
        self.logger.error(message)
    
    def critical(self, message: str):
        self.logger.critical(message)

# Global logger instance
enhanced_logger = EnhancedLogger()

def get_logger():
    """Get the global enhanced logger instance."""
    return enhanced_logger 