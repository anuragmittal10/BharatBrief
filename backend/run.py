"""
Entry point for the BharatBrief backend server.
"""

import logging
import sys
import atexit

from dotenv import load_dotenv

# Load environment variables before anything else
load_dotenv()

from config.settings import CONFIG
from services.firebase_service import init_firebase
from services.gemini_service import init_gemini
from services.scheduler_service import setup_scheduler, shutdown_scheduler
from app import create_app

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)


def main():
    logger.info("Starting BharatBrief backend...")

    # 1. Initialize Firebase (optional — runs in demo mode without it)
    from services.firebase_service import ensure_demo_seeded
    firebase_creds = CONFIG.get("FIREBASE_CREDENTIALS_PATH")
    if firebase_creds and firebase_creds not in ("./firebase-service-account.json", "your_firebase_credentials_path_here", ""):
        import os
        if os.path.exists(firebase_creds):
            if not init_firebase(firebase_creds):
                logger.warning("Firebase initialization failed. Running in DEMO mode.")
                ensure_demo_seeded()
        else:
            logger.info("Firebase credentials file not found at '%s'. Running in DEMO mode.", firebase_creds)
            ensure_demo_seeded()
    else:
        logger.info("No Firebase credentials configured. Running in DEMO mode with sample data.")
        ensure_demo_seeded()

    # 2. Initialize Gemini
    gemini_key = CONFIG.get("GEMINI_API_KEY")
    if gemini_key:
        if not init_gemini(gemini_key):
            logger.warning("Gemini initialization failed. Summarization will use fallback.")
    else:
        logger.warning("GEMINI_API_KEY not set. Summarization will use fallback.")

    # 3. Create Flask app
    app = create_app()

    # 4. Start scheduler
    scheduler = setup_scheduler()
    atexit.register(shutdown_scheduler)

    # 5. Run Flask
    host = CONFIG.get("FLASK_HOST", "0.0.0.0")
    port = int(CONFIG.get("FLASK_PORT", 8000))
    debug = CONFIG.get("FLASK_DEBUG", False)

    logger.info("Server starting on %s:%d (debug=%s)", host, port, debug)
    app.run(host=host, port=port, debug=debug, use_reloader=False)


if __name__ == "__main__":
    main()
