import logging
import importlib.resources as resources

logger = logging.getLogger(__name__)

def get_web_interface_html():
    """Loads the enhanced HTML for the web interface using importlib.resources."""
    try:
        with resources.files('whisperlivekit.web').joinpath('live_transcription_with_recordings_enhanced.html').open('r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        logger.error(f"Error loading enhanced web interface HTML: {e}")
        return "<html><body><h1>Error loading enhanced interface</h1></body></html>" 