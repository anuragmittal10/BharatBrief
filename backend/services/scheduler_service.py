"""
APScheduler-based job scheduler for BharatBrief background tasks.
"""

import logging
from datetime import datetime, timezone

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger

from config.settings import CONFIG
from config.languages import SUPPORTED_LANGUAGES

logger = logging.getLogger(__name__)

_scheduler = None


def fetch_and_process():
    """
    Main pipeline: fetch RSS -> deduplicate -> summarize -> translate -> save.
    Runs every FETCH_INTERVAL_MINUTES (default 15 min).
    """
    from services.rss_service import fetch_all_feeds, deduplicate, filter_old_articles
    from services.gemini_service import summarize_batch
    from services.bhashini_service import translate_article_to_all_languages
    from services.firebase_service import article_exists, save_article

    logger.info("=== Starting fetch_and_process pipeline ===")

    try:
        # 1. Fetch all RSS feeds
        articles = fetch_all_feeds()

        # 2. Filter old articles
        max_age = CONFIG.get("MAX_ARTICLE_AGE_HOURS", 48)
        articles = filter_old_articles(articles, max_age_hours=max_age)

        # 3. Deduplicate
        articles = deduplicate(articles)

        # 4. Filter out articles already in the database
        new_articles = []
        for article in articles:
            if not article_exists(article["id"]):
                new_articles.append(article)

        logger.info("New articles to process: %d (out of %d fetched)", len(new_articles), len(articles))

        if not new_articles:
            logger.info("No new articles to process.")
            return

        # 5. Summarize with Gemini
        batch_size = CONFIG.get("GEMINI_BATCH_SIZE", 50)
        batch_delay = CONFIG.get("GEMINI_BATCH_DELAY", 2)
        new_articles = summarize_batch(new_articles, batch_size=batch_size, batch_delay=batch_delay)

        # 6. Translate to all languages and save
        for article in new_articles:
            try:
                source_lang = article.get("language", "en")
                translations = translate_article_to_all_languages(
                    {"headline": article["headline"], "summary": article["summary"]},
                    source_lang=source_lang,
                )
                article["translations"] = translations

                # Convert datetime to ISO string for Firestore
                pub = article.get("published_at")
                if isinstance(pub, datetime):
                    article["published_at"] = pub.isoformat()

                save_article(article)
            except Exception as e:
                logger.error("Error processing article '%s': %s", article.get("title", "")[:50], e)

        logger.info("=== Pipeline complete. Processed %d articles ===", len(new_articles))

    except Exception as e:
        logger.error("Pipeline error: %s", e)


def generate_tts_trending():
    """
    Pre-generate TTS for top 50 trending articles per language.
    Runs every 30 minutes.
    """
    from services.firebase_service import get_trending_articles, update_tts_url
    from services.bhashini_service import generate_tts, save_tts_audio

    logger.info("Starting TTS generation for trending articles")

    for lang in SUPPORTED_LANGUAGES:
        lang_code = lang["code"]
        try:
            articles = get_trending_articles(language=lang_code, limit=50)
            for article in articles:
                # Skip if TTS already exists for this language
                existing_tts = article.get("tts_urls", {})
                if lang_code in existing_tts:
                    continue

                text = article.get("summary") or article.get("description", "")
                if not text:
                    continue

                audio_bytes = generate_tts(text, lang_code)
                if audio_bytes:
                    url = save_tts_audio(article["id"], lang_code, audio_bytes)
                    if url:
                        update_tts_url(article["id"], lang_code, url)

        except Exception as e:
            logger.error("TTS generation error for %s: %s", lang_code, e)

    logger.info("TTS generation cycle complete")


def generate_daily_quiz():
    """Generate the daily quiz from top articles. Runs at 7:30 PM."""
    from services.firebase_service import get_trending_articles, save_quiz
    from services.gemini_service import generate_quiz_questions

    logger.info("Generating daily quiz")

    try:
        articles = get_trending_articles(language="en", limit=20)
        if not articles:
            logger.warning("No articles available for quiz generation")
            return

        questions = generate_quiz_questions(articles)
        if not questions:
            logger.warning("Failed to generate quiz questions")
            return

        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        quiz_data = {
            "date": today,
            "questions": questions,
            "total_questions": len(questions),
        }
        save_quiz(quiz_data)
        logger.info("Daily quiz generated with %d questions", len(questions))
    except Exception as e:
        logger.error("Error generating daily quiz: %s", e)


def send_morning_digest_job():
    """Send morning digest for all languages. Runs at 8:00 AM."""
    from services.notification_service import send_morning_digest

    for lang in SUPPORTED_LANGUAGES:
        try:
            send_morning_digest(language=lang["code"])
        except Exception as e:
            logger.error("Morning digest error for %s: %s", lang["code"], e)


def send_evening_digest_job():
    """Send evening digest for all languages. Runs at 8:00 PM."""
    from services.notification_service import send_evening_digest, send_quiz_reminder

    for lang in SUPPORTED_LANGUAGES:
        try:
            send_evening_digest(language=lang["code"])
        except Exception as e:
            logger.error("Evening digest error for %s: %s", lang["code"], e)

    try:
        send_quiz_reminder()
    except Exception as e:
        logger.error("Quiz reminder error: %s", e)


def cleanup_old_articles_job():
    """Remove articles older than 7 days. Runs daily."""
    from services.firebase_service import cleanup_old_articles

    try:
        count = cleanup_old_articles(max_age_days=7)
        logger.info("Cleanup job removed %d old articles", count)
    except Exception as e:
        logger.error("Cleanup error: %s", e)


def setup_scheduler():
    """Configure and start the APScheduler with all cron jobs."""
    global _scheduler

    _scheduler = BackgroundScheduler(timezone="Asia/Kolkata")

    fetch_interval = CONFIG.get("FETCH_INTERVAL_MINUTES", 15)

    # Fetch and process articles every N minutes
    _scheduler.add_job(
        fetch_and_process,
        trigger=IntervalTrigger(minutes=fetch_interval),
        id="fetch_and_process",
        name="Fetch and process RSS feeds",
        replace_existing=True,
    )

    # Pre-generate TTS every 30 minutes
    _scheduler.add_job(
        generate_tts_trending,
        trigger=IntervalTrigger(minutes=30),
        id="generate_tts_trending",
        name="Generate TTS for trending articles",
        replace_existing=True,
    )

    # Generate daily quiz at 7:30 PM IST
    _scheduler.add_job(
        generate_daily_quiz,
        trigger=CronTrigger(hour=19, minute=30),
        id="generate_daily_quiz",
        name="Generate daily quiz",
        replace_existing=True,
    )

    # Send morning digest at 8:00 AM IST
    _scheduler.add_job(
        send_morning_digest_job,
        trigger=CronTrigger(hour=8, minute=0),
        id="send_morning_digest",
        name="Send morning digest",
        replace_existing=True,
    )

    # Send evening digest at 8:00 PM IST
    _scheduler.add_job(
        send_evening_digest_job,
        trigger=CronTrigger(hour=20, minute=0),
        id="send_evening_digest",
        name="Send evening digest",
        replace_existing=True,
    )

    # Cleanup old articles daily at 3:00 AM IST
    _scheduler.add_job(
        cleanup_old_articles_job,
        trigger=CronTrigger(hour=3, minute=0),
        id="cleanup_old_articles",
        name="Cleanup old articles",
        replace_existing=True,
    )

    _scheduler.start()
    logger.info("Scheduler started with %d jobs", len(_scheduler.get_jobs()))

    return _scheduler


def shutdown_scheduler():
    """Gracefully shut down the scheduler."""
    global _scheduler
    if _scheduler:
        _scheduler.shutdown(wait=False)
        logger.info("Scheduler shut down")
        _scheduler = None
