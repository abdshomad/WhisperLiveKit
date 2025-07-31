import logging
import importlib.resources as resources

logger = logging.getLogger(__name__)

def get_web_interface_html():
    """Loads the enhanced HTTPS HTML for the web interface using importlib.resources."""
    try:
        with resources.files('whisperlivekit.web').joinpath('live_transcription_with_recordings_enhanced_https.html').open('r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        logger.error(f"Error loading enhanced HTTPS web interface HTML: {e}")
        return "<html><body><h1>Error loading enhanced HTTPS interface</h1></body></html>" 