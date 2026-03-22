"""
Entry point for the BharatBrief backend server.
"""

import logging
import os
import sys

from dotenv import load_dotenv

# Load environment variables before anything else
load_dotenv()

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

    # Create Flask app (handles demo seeding and auto-fetch internally)
    from app import create_app
    app = create_app()

    # Run Flask
    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("PORT", os.getenv("FLASK_PORT", "8000")))
    debug = os.getenv("FLASK_DEBUG", "False").lower() == "true"

    logger.info("Server starting on %s:%d (debug=%s)", host, port, debug)
    app.run(host=host, port=port, debug=debug, use_reloader=False)


if __name__ == "__main__":
    main()
