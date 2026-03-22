"""
Central configuration loaded from environment variables.
"""

import os
import logging

logger = logging.getLogger(__name__)


def load_config():
    """Load and validate all configuration from environment variables."""
    config = {
        # Gemini AI
        "GEMINI_API_KEY": os.getenv("GEMINI_API_KEY"),

        # Firebase
        "FIREBASE_CREDENTIALS_PATH": os.getenv("FIREBASE_CREDENTIALS_PATH"),

        # Bhashini API (ULCA)
        "BHASHINI_USER_ID": os.getenv("BHASHINI_USER_ID"),
        "BHASHINI_API_KEY": os.getenv("BHASHINI_API_KEY"),
        "BHASHINI_AUTH_TOKEN": os.getenv("BHASHINI_AUTH_TOKEN"),

        # Scheduler settings
        "FETCH_INTERVAL_MINUTES": int(os.getenv("FETCH_INTERVAL_MINUTES", "15")),
        "MAX_ARTICLE_AGE_HOURS": int(os.getenv("MAX_ARTICLE_AGE_HOURS", "48")),
        "GEMINI_BATCH_SIZE": int(os.getenv("GEMINI_BATCH_SIZE", "50")),
        "GEMINI_BATCH_DELAY": int(os.getenv("GEMINI_BATCH_DELAY", "2")),

        # Flask
        "FLASK_HOST": os.getenv("FLASK_HOST", "0.0.0.0"),
        "FLASK_PORT": int(os.getenv("FLASK_PORT", "8000")),
        "FLASK_DEBUG": os.getenv("FLASK_DEBUG", "False").lower() == "true",
    }

    # Validate required keys
    required_keys = ["GEMINI_API_KEY", "FIREBASE_CREDENTIALS_PATH"]
    missing = [k for k in required_keys if not config.get(k)]
    if missing:
        logger.warning("Missing required config keys: %s", ", ".join(missing))

    return config


# Module-level config singleton
CONFIG = load_config()
