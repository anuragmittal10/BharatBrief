"""
Main Flask application for BharatBrief API.
"""

import json
import logging
from datetime import datetime, timezone

from flask import Flask, request, jsonify
from flask.json.provider import DefaultJSONProvider
from flask_cors import CORS

from config.languages import SUPPORTED_LANGUAGES
from config.rss_feeds import CATEGORIES
from services import firebase_service

logger = logging.getLogger(__name__)


class BharatBriefJSONProvider(DefaultJSONProvider):
    """Custom JSON provider that serializes datetime objects."""

    def default(self, o):
        if isinstance(o, datetime):
            return o.isoformat()
        return super().default(o)


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.json_provider_class = BharatBriefJSONProvider
    app.json = BharatBriefJSONProvider(app)
    CORS(app)

    # Start recurring RSS fetch scheduler
    _scheduler_started = [False]

    @app.before_request
    def _start_scheduler_once():
        if not _scheduler_started[0]:
            _scheduler_started[0] = True
            import threading
            # Fetch immediately on first request
            threading.Thread(target=_fetch_rss_lightweight, daemon=True).start()
            # Start recurring fetch every 5 minutes
            threading.Thread(target=_run_recurring_fetch, daemon=True).start()
            logger.info("Started RSS fetch scheduler (every 5 min)")

    # ─── Error Handlers ─────────────────────────────────────────────────

    @app.errorhandler(400)
    def bad_request(e):
        return jsonify({"error": "Bad request", "message": str(e)}), 400

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Not found", "message": str(e)}), 404

    @app.errorhandler(500)
    def internal_error(e):
        logger.error("Internal server error: %s", e)
        return jsonify({"error": "Internal server error"}), 500

    # ─── Health Check ────────────────────────────────────────────────────

    @app.route("/api/health", methods=["GET"])
    def health_check():
        return jsonify({"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()})

    # ─── Manual Trigger ──────────────────────────────────────────────────

    @app.route("/api/trigger-fetch", methods=["POST"])
    def trigger_fetch():
        """POST /api/trigger-fetch — manually trigger RSS fetch (lightweight, no Gemini/Bhashini)."""
        import threading
        threading.Thread(target=_fetch_rss_lightweight, daemon=True).start()
        return jsonify({"success": True, "message": "Lightweight fetch triggered in background."})

    def _run_recurring_fetch():
        """Run RSS fetch every 5 minutes."""
        import time as _time
        while True:
            _time.sleep(300)  # 5 minutes
            try:
                _fetch_rss_lightweight()
                _cleanup_old_articles()
            except Exception as e:
                logger.error("Recurring fetch error: %s", e)

    def _cleanup_old_articles():
        """Remove articles older than 48 hours from in-memory store."""
        from services.firebase_service import _mem_articles, _demo_mode
        if not _demo_mode:
            return
        from datetime import timedelta
        cutoff = datetime.now(timezone.utc) - timedelta(hours=48)
        old_ids = []
        for aid, article in _mem_articles.items():
            pub = article.get("published_at")
            if pub and isinstance(pub, datetime) and pub < cutoff:
                old_ids.append(aid)
        for aid in old_ids:
            del _mem_articles[aid]
        if old_ids:
            logger.info("Cleaned up %d old articles (>48h)", len(old_ids))

    def _gemini_summarize(title, description):
        """Use Gemini to generate a 60-word summary when RSS content is too short."""
        import os
        api_key = os.getenv("GEMINI_API_KEY", "")
        if not api_key:
            return None, None

        try:
            import google.generativeai as genai
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel("gemini-2.0-flash")

            prompt = f"""You are a news summarizer for an Indian news app called BharatBrief.
Given this news article title and description, write:
1. A crisp headline (max 12 words)
2. A neutral, informative summary (exactly 50-60 words)

Title: {title}
Description: {description or 'No description available'}

Respond in this exact format (no markdown, no quotes):
HEADLINE: <your headline>
SUMMARY: <your 50-60 word summary>"""

            response = model.generate_content(prompt)
            text = response.text.strip()

            headline = title
            summary = ""
            for line in text.split("\n"):
                line = line.strip()
                if line.upper().startswith("HEADLINE:"):
                    headline = line.split(":", 1)[1].strip()
                elif line.upper().startswith("SUMMARY:"):
                    summary = line.split(":", 1)[1].strip()

            if summary and len(summary.split()) >= 20:
                return headline, summary
        except Exception as e:
            logger.warning("Gemini summarize failed for '%s': %s", title[:50], e)

        return None, None

    def _fetch_rss_lightweight():
        """Fetch RSS feeds, use Gemini to summarize short articles."""
        from services.rss_service import fetch_all_feeds, deduplicate, filter_old_articles
        from utils.helpers import truncate_text
        import time as _time

        try:
            logger.info("=== Starting lightweight RSS fetch ===")
            articles = fetch_all_feeds()
            articles = filter_old_articles(articles, max_age_hours=48)
            articles = deduplicate(articles)

            saved = 0
            gemini_used = 0
            for article in articles:
                if firebase_service.article_exists(article["id"]):
                    continue

                title = article.get("title", "")
                description = article.get("description", "")
                headline = title[:100]
                summary = truncate_text(description, word_count=60)

                # If summary is too short (< 15 words), use Gemini
                if not summary or len(summary.split()) < 15:
                    ai_headline, ai_summary = _gemini_summarize(title, description)
                    if ai_summary:
                        headline = ai_headline or headline
                        summary = ai_summary
                        gemini_used += 1
                        _time.sleep(0.3)  # Rate limit Gemini calls
                    elif not summary:
                        summary = title  # Last resort fallback

                article_data = {
                    "id": article["id"],
                    "title": title,
                    "source": article["source"],
                    "category": article["category"],
                    "state": article.get("state"),
                    "image_url": article.get("image_url"),
                    "original_link": article.get("link", ""),
                    "published_at": article.get("published_at", datetime.now(timezone.utc)),
                    "summaries": {
                        "en": {"headline": headline, "summary": summary},
                    },
                    "tts_urls": {},
                    "is_trending": saved < 20,
                    "mood_tag": "neutral",
                    "language": article.get("language", "en"),
                }
                firebase_service.save_article(article_data)
                saved += 1

            logger.info("=== Fetch complete. Saved %d articles (%d Gemini-enhanced) ===", saved, gemini_used)
        except Exception as e:
            logger.error("Lightweight fetch error: %s", e)

    # ─── Articles ────────────────────────────────────────────────────────

    @app.route("/api/articles", methods=["GET"])
    def get_articles():
        """
        GET /api/articles?lang=hi&category=national&state=MH&page=1&limit=20
        """
        try:
            language = request.args.get("lang", "en")
            category = request.args.get("category", "all")
            state = request.args.get("state")
            limit = min(int(request.args.get("limit", 20)), 100)

            articles, _ = firebase_service.get_articles(
                language=language,
                category=category,
                state=state,
                limit=limit,
            )

            return jsonify({
                "success": True,
                "count": len(articles),
                "articles": articles,
            })
        except Exception as e:
            logger.error("Error in get_articles: %s", e)
            return jsonify({"error": str(e)}), 500

    @app.route("/api/articles/<article_id>", methods=["GET"])
    def get_article(article_id):
        """GET /api/articles/<id>"""
        try:
            article = firebase_service.get_article_by_id(article_id)
            if not article:
                return jsonify({"error": "Article not found"}), 404
            return jsonify({"success": True, "article": article})
        except Exception as e:
            logger.error("Error in get_article: %s", e)
            return jsonify({"error": str(e)}), 500

    @app.route("/api/articles/<article_id>/deep", methods=["GET"])
    def get_deep_summary(article_id):
        """GET /api/articles/<id>/deep - extended Deep Mode summary."""
        try:
            article = firebase_service.get_article_by_id(article_id)
            if not article:
                return jsonify({"error": "Article not found"}), 404

            from services.gemini_service import generate_deep_summary
            deep = generate_deep_summary(
                article.get("title", ""),
                article.get("description", ""),
            )
            return jsonify({"success": True, "deep_summary": deep})
        except Exception as e:
            logger.error("Error in get_deep_summary: %s", e)
            return jsonify({"error": str(e)}), 500

    # ─── Trending ────────────────────────────────────────────────────────

    @app.route("/api/trending", methods=["GET"])
    def get_trending():
        """GET /api/trending?lang=hi&limit=50"""
        try:
            language = request.args.get("lang", "en")
            limit = min(int(request.args.get("limit", 50)), 100)
            articles = firebase_service.get_trending_articles(language=language, limit=limit)
            return jsonify({
                "success": True,
                "count": len(articles),
                "articles": articles,
            })
        except Exception as e:
            logger.error("Error in get_trending: %s", e)
            return jsonify({"error": str(e)}), 500

    # ─── TTS ─────────────────────────────────────────────────────────────

    @app.route("/api/tts/<article_id>/<lang>", methods=["GET"])
    def get_tts(article_id, lang):
        """
        GET /api/tts/<article_id>/<lang>
        Returns existing TTS URL or generates on-demand.
        """
        try:
            article = firebase_service.get_article_by_id(article_id)
            if not article:
                return jsonify({"error": "Article not found"}), 404

            # Check if TTS already exists
            existing_url = article.get("tts_urls", {}).get(lang)
            if existing_url:
                return jsonify({"success": True, "tts_url": existing_url})

            # Generate on-demand
            text = article.get("summary") or article.get("description", "")
            # Use translated summary if available
            translations = article.get("translations", {})
            if lang in translations:
                text = translations[lang].get("summary", text)

            if not text:
                return jsonify({"error": "No text available for TTS"}), 400

            from services.bhashini_service import generate_tts, save_tts_audio
            audio_bytes = generate_tts(text, lang)
            if not audio_bytes:
                return jsonify({"error": "TTS generation failed"}), 500

            url = save_tts_audio(article_id, lang, audio_bytes)
            if url:
                firebase_service.update_tts_url(article_id, lang, url)
                return jsonify({"success": True, "tts_url": url})

            return jsonify({"error": "Failed to save TTS audio"}), 500
        except Exception as e:
            logger.error("Error in get_tts: %s", e)
            return jsonify({"error": str(e)}), 500

    # ─── Quiz ────────────────────────────────────────────────────────────

    @app.route("/api/quiz/today", methods=["GET"])
    def get_today_quiz():
        """GET /api/quiz/today"""
        try:
            quiz = firebase_service.get_today_quiz()
            if not quiz:
                return jsonify({"error": "No quiz available today"}), 404
            return jsonify({"success": True, "quiz": quiz})
        except Exception as e:
            logger.error("Error in get_today_quiz: %s", e)
            return jsonify({"error": str(e)}), 500

    @app.route("/api/quiz/submit", methods=["POST"])
    def submit_quiz():
        """
        POST /api/quiz/submit
        Body: {"uid": "...", "answers": [0,1,2,3,1], "score": 4}
        """
        try:
            data = request.get_json()
            if not data:
                return jsonify({"error": "No data provided"}), 400

            uid = data.get("uid")
            score = data.get("score", 0)

            if not uid:
                return jsonify({"error": "uid is required"}), 400

            # Update user's quiz score
            user = firebase_service.get_user(uid)
            if user:
                total_score = user.get("quiz_score", 0) + score
                quizzes_taken = user.get("quizzes_taken", 0) + 1
                firebase_service.save_user({
                    "uid": uid,
                    "quiz_score": total_score,
                    "quizzes_taken": quizzes_taken,
                })

            return jsonify({"success": True, "message": "Quiz submitted"})
        except Exception as e:
            logger.error("Error in submit_quiz: %s", e)
            return jsonify({"error": str(e)}), 500

    # ─── User ────────────────────────────────────────────────────────────

    @app.route("/api/user/register", methods=["POST"])
    def register_user():
        """POST /api/user/register - create anonymous user."""
        try:
            data = request.get_json() or {}
            uid = data.get("uid")
            if not uid:
                import uuid
                uid = str(uuid.uuid4())

            user_data = {
                "uid": uid,
                "preferences": data.get("preferences", {
                    "language": "en",
                    "categories": ["all"],
                    "state": None,
                }),
                "bookmarks": [],
                "quiz_score": 0,
                "quizzes_taken": 0,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
            firebase_service.save_user(user_data)
            return jsonify({"success": True, "uid": uid, "user": user_data}), 201
        except Exception as e:
            logger.error("Error in register_user: %s", e)
            return jsonify({"error": str(e)}), 500

    @app.route("/api/user/<uid>/preferences", methods=["PUT"])
    def update_preferences(uid):
        """PUT /api/user/<uid>/preferences"""
        try:
            prefs = request.get_json()
            if not prefs:
                return jsonify({"error": "No preferences provided"}), 400
            success = firebase_service.update_user_prefs(uid, prefs)
            if success:
                return jsonify({"success": True, "message": "Preferences updated"})
            return jsonify({"error": "Failed to update preferences"}), 500
        except Exception as e:
            logger.error("Error in update_preferences: %s", e)
            return jsonify({"error": str(e)}), 500

    @app.route("/api/user/<uid>/bookmarks", methods=["GET"])
    def get_bookmarks(uid):
        """GET /api/user/<uid>/bookmarks"""
        try:
            articles = firebase_service.get_bookmarks(uid)
            return jsonify({"success": True, "count": len(articles), "articles": articles})
        except Exception as e:
            logger.error("Error in get_bookmarks: %s", e)
            return jsonify({"error": str(e)}), 500

    @app.route("/api/user/<uid>/bookmarks/<article_id>", methods=["POST"])
    def add_bookmark(uid, article_id):
        """POST /api/user/<uid>/bookmarks/<article_id>"""
        try:
            success = firebase_service.add_bookmark(uid, article_id)
            if success:
                return jsonify({"success": True, "message": "Bookmark added"})
            return jsonify({"error": "Failed to add bookmark"}), 500
        except Exception as e:
            logger.error("Error in add_bookmark: %s", e)
            return jsonify({"error": str(e)}), 500

    @app.route("/api/user/<uid>/bookmarks/<article_id>", methods=["DELETE"])
    def delete_bookmark(uid, article_id):
        """DELETE /api/user/<uid>/bookmarks/<article_id>"""
        try:
            success = firebase_service.remove_bookmark(uid, article_id)
            if success:
                return jsonify({"success": True, "message": "Bookmark removed"})
            return jsonify({"error": "Failed to remove bookmark"}), 500
        except Exception as e:
            logger.error("Error in delete_bookmark: %s", e)
            return jsonify({"error": str(e)}), 500

    @app.route("/api/user/fcm-token", methods=["POST"])
    def register_fcm_token():
        """POST /api/user/fcm-token"""
        try:
            data = request.get_json()
            if not data or not data.get("uid") or not data.get("token"):
                return jsonify({"error": "uid and token are required"}), 400

            uid = data["uid"]
            token = data["token"]
            firebase_service.save_fcm_token(uid, token)

            # Subscribe to default topics
            from services.notification_service import subscribe_to_topic
            topics = data.get("topics", [f"digest_{data.get('language', 'en')}", "quiz"])
            for topic in topics:
                subscribe_to_topic(token, topic)

            return jsonify({"success": True, "message": "FCM token registered"})
        except Exception as e:
            logger.error("Error in register_fcm_token: %s", e)
            return jsonify({"error": str(e)}), 500

    # ─── Config Endpoints ────────────────────────────────────────────────

    @app.route("/api/languages", methods=["GET"])
    def get_languages():
        """GET /api/languages"""
        return jsonify({"success": True, "languages": SUPPORTED_LANGUAGES})

    @app.route("/api/categories", methods=["GET"])
    def get_categories():
        """GET /api/categories"""
        return jsonify({"success": True, "categories": CATEGORIES})

    # ─── Feedback ────────────────────────────────────────────────────────

    @app.route("/api/feedback", methods=["POST"])
    def submit_feedback():
        """POST /api/feedback - report bad translation, etc."""
        try:
            data = request.get_json()
            if not data:
                return jsonify({"error": "No data provided"}), 400

            feedback_data = {
                "article_id": data.get("article_id"),
                "language": data.get("language"),
                "type": data.get("type", "general"),
                "message": data.get("message", ""),
                "uid": data.get("uid"),
            }
            firebase_service.save_feedback(feedback_data)
            return jsonify({"success": True, "message": "Feedback submitted"})
        except Exception as e:
            logger.error("Error in submit_feedback: %s", e)
            return jsonify({"error": str(e)}), 500

    # ─── Stats (admin) ───────────────────────────────────────────────────

    @app.route("/api/stats", methods=["GET"])
    def get_stats():
        """GET /api/stats - article statistics."""
        try:
            stats = firebase_service.get_article_stats()
            return jsonify({"success": True, "stats": stats})
        except Exception as e:
            logger.error("Error in get_stats: %s", e)
            return jsonify({"error": str(e)}), 500

    return app
