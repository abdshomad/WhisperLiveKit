import os
import subprocess
from datetime import datetime
from typing import Dict, Any

class VersionInfo:
    """Version and build information for WhisperLiveKit."""
    
    def __init__(self):
        self.version = "1.0.0"
        self.build_date = self._get_build_date()
        self.git_info = self._get_git_info()
        self.dependencies = self._get_dependencies()
    
    def _get_build_date(self) -> str:
        """Get the build date from git or current time."""
        try:
            # Try to get the last commit date
            result = subprocess.run(
                ["git", "log", "-1", "--format=%cd", "--date=iso"],
                capture_output=True, text=True, cwd=os.path.dirname(__file__)
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except (subprocess.SubprocessError, FileNotFoundError):
            pass
        
        # Fallback to current time
        return datetime.now().isoformat()
    
    def _get_git_info(self) -> Dict[str, str]:
        """Get git information."""
        git_info = {}
        try:
            # Get current branch
            result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                capture_output=True, text=True, cwd=os.path.dirname(__file__)
            )
            if result.returncode == 0:
                git_info["branch"] = result.stdout.strip()
            
            # Get commit hash
            result = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                capture_output=True, text=True, cwd=os.path.dirname(__file__)
            )
            if result.returncode == 0:
                git_info["commit"] = result.stdout.strip()[:8]
            
            # Get last commit message
            result = subprocess.run(
                ["git", "log", "-1", "--format=%s"],
                capture_output=True, text=True, cwd=os.path.dirname(__file__)
            )
            if result.returncode == 0:
                git_info["last_commit"] = result.stdout.strip()
                
        except (subprocess.SubprocessError, FileNotFoundError):
            git_info["error"] = "Git information not available"
        
        return git_info
    
    def _get_dependencies(self) -> Dict[str, str]:
        """Get key dependency versions."""
        dependencies = {}
        
        # Try to get torch version
        try:
            import torch
            dependencies["torch"] = torch.__version__
        except ImportError:
            dependencies["torch"] = "Not installed"
        
        # Try to get transformers version
        try:
            import transformers
            dependencies["transformers"] = transformers.__version__
        except ImportError:
            dependencies["transformers"] = "Not installed"
        
        # Try to get faster-whisper version
        try:
            import faster_whisper
            dependencies["faster-whisper"] = faster_whisper.__version__
        except ImportError:
            dependencies["faster-whisper"] = "Not installed"
        
        # Try to get fastapi version
        try:
            import fastapi
            dependencies["fastapi"] = fastapi.__version__
        except ImportError:
            dependencies["fastapi"] = "Not installed"
        
        return dependencies
    
    def get_version_dict(self) -> Dict[str, Any]:
        """Get complete version information as a dictionary."""
        return {
            "version": self.version,
            "build_date": self.build_date,
            "git_info": self.git_info,
            "dependencies": self.dependencies,
            "python_version": f"{os.sys.version_info.major}.{os.sys.version_info.minor}.{os.sys.version_info.micro}",
            "platform": os.sys.platform
        }
    
    def get_version_string(self) -> str:
        """Get a formatted version string."""
        git_branch = self.git_info.get("branch", "unknown")
        git_commit = self.git_info.get("commit", "unknown")
        return f"v{self.version} ({git_branch}/{git_commit}) - Built: {self.build_date}"
    
    def get_footer_info(self) -> Dict[str, Any]:
        """Get information suitable for the footer."""
        return {
            "version": self.version,
            "build_date": self.build_date,
            "git_branch": self.git_info.get("branch", "unknown"),
            "git_commit": self.git_info.get("commit", "unknown"),
            "python_version": f"{os.sys.version_info.major}.{os.sys.version_info.minor}.{os.sys.version_info.micro}"
        }

# Global version info instance
version_info = VersionInfo()

def get_version_info() -> VersionInfo:
    """Get the global version info instance."""
    return version_info 