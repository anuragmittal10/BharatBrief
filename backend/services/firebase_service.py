"""
Firebase Firestore and Storage service for BharatBrief.
Falls back to in-memory storage when Firebase credentials are not configured.
"""

import logging
import uuid
from datetime import datetime, timezone, timedelta
from collections import defaultdict

logger = logging.getLogger(__name__)

_db = None
_bucket = None
_demo_mode = True

# ─── In-Memory Store (Demo Mode) ─────────────────────────────────────────────

_mem_articles = {}
_mem_users = {}
_mem_quizzes = {}
_mem_feedback = []


def _seed_demo_data():
    """Populate in-memory store with sample articles for demo."""
    import hashlib

    categories = ["national", "sports", "tech", "business", "entertainment", "world"]
    sources = ["NDTV", "Times of India", "The Hindu", "Indian Express", "Hindustan Times", "BBC"]

    sample_articles = [
        {
            "title": "India Successfully Launches Gaganyaan Unmanned Mission",
            "headline": "India launches Gaganyaan test mission",
            "summary": "ISRO successfully launched the first unmanned test flight of its Gaganyaan human spaceflight programme from Sriharikota today. The mission will test critical systems including crew escape mechanism and life support before sending Indian astronauts to space in 2027. PM Modi congratulated the ISRO team.",
            "category": "national",
            "source": "NDTV",
            "image_url": "https://picsum.photos/seed/gaganyaan/800/400",
            "mood_tag": "positive",
        },
        {
            "title": "Sensex Crosses 85,000 Mark for First Time",
            "headline": "Sensex hits all-time high of 85,000",
            "summary": "The BSE Sensex crossed the historic 85,000 mark today, driven by strong FII inflows and robust quarterly earnings from banking and IT sectors. Nifty50 also touched a new high of 25,800. Analysts credit stable macroeconomic conditions and growing investor confidence in Indian markets.",
            "category": "business",
            "source": "Business Standard",
            "image_url": "https://picsum.photos/seed/sensex/800/400",
            "mood_tag": "positive",
        },
        {
            "title": "India Beat Australia in Thrilling Cricket Test Match",
            "headline": "India wins 4th Test by 3 wickets",
            "summary": "India clinched a dramatic victory over Australia in the fourth Test at Brisbane, winning by just 3 wickets in a tense final session. Rishabh Pant scored an unbeaten 89 to guide the chase of 328. The series is now tied 2-2 with the final Test at Sydney next week.",
            "category": "sports",
            "source": "ESPN Cricinfo",
            "image_url": "https://picsum.photos/seed/cricket/800/400",
            "mood_tag": "positive",
        },
        {
            "title": "NVIDIA Unveils New AI Chip Designed for Indian Market",
            "headline": "NVIDIA launches India-specific AI chip",
            "summary": "NVIDIA announced a new AI accelerator chip optimized for the Indian market, featuring support for Indic language models and lower power consumption suited for Indian data centers. The chip will be manufactured in partnership with Tata Electronics and priced competitively for Indian startups and enterprises.",
            "category": "tech",
            "source": "Gadgets360",
            "image_url": "https://picsum.photos/seed/nvidia/800/400",
            "mood_tag": "neutral",
        },
        {
            "title": "Shah Rukh Khan Announces New Pan-India Film",
            "headline": "SRK announces multilingual epic film",
            "summary": "Bollywood superstar Shah Rukh Khan announced his next mega-budget film which will release simultaneously in Hindi, Tamil, Telugu, and Malayalam. The historical epic will be directed by S.S. Rajamouli and is expected to be the most expensive Indian film ever made with a budget of 700 crores.",
            "category": "entertainment",
            "source": "Bollywood Hungama",
            "image_url": "https://picsum.photos/seed/srk/800/400",
            "mood_tag": "positive",
        },
        {
            "title": "UN Climate Summit Reaches Historic Agreement",
            "headline": "UN summit agrees on climate fund",
            "summary": "The United Nations Climate Summit concluded with a historic agreement to establish a 500 billion dollar global climate fund. India played a key role in negotiations, securing provisions for developing nations. The agreement includes binding targets for carbon emission reductions by 2035 and technology transfer mechanisms.",
            "category": "world",
            "source": "Reuters",
            "image_url": "https://picsum.photos/seed/climate/800/400",
            "mood_tag": "positive",
        },
        {
            "title": "Delhi Metro Phase 5 Gets Cabinet Approval",
            "headline": "Cabinet approves Delhi Metro Phase 5",
            "summary": "The Union Cabinet approved the Delhi Metro Phase 5 expansion covering 45 kilometers with 28 new stations connecting peripheral areas of the NCR region. The project estimated at 12,000 crores will be completed by 2029. It will benefit an additional 8 lakh daily commuters and reduce road congestion.",
            "category": "national",
            "source": "Hindustan Times",
            "image_url": "https://picsum.photos/seed/metro/800/400",
            "mood_tag": "positive",
        },
        {
            "title": "UPI Transactions Cross 20 Billion in March 2026",
            "headline": "UPI hits 20 billion monthly transactions",
            "summary": "India's Unified Payments Interface recorded over 20 billion transactions in March 2026, cementing its position as the world's largest real-time payment system. The total transaction value exceeded 25 lakh crores. NPCI announced plans to expand UPI to 10 more countries by year end.",
            "category": "business",
            "source": "Moneycontrol",
            "image_url": "https://picsum.photos/seed/upi/800/400",
            "mood_tag": "positive",
        },
        {
            "title": "AI Startup Krutrim Raises 1 Billion Dollar Funding",
            "headline": "Krutrim becomes India's AI unicorn",
            "summary": "Bengaluru-based AI startup Krutrim, founded by Ola's Bhavish Aggarwal, raised 1 billion dollars in Series B funding led by SoftBank and Sequoia. The company's Indic language AI models now support 22 Indian languages and are being used by government agencies and enterprises across India.",
            "category": "tech",
            "source": "TechCrunch",
            "image_url": "https://picsum.photos/seed/krutrim/800/400",
            "mood_tag": "positive",
        },
        {
            "title": "Indian Railways Launches Hydrogen-Powered Train",
            "headline": "India's first hydrogen train flagged off",
            "summary": "Indian Railways flagged off the country's first hydrogen fuel cell powered train on the Jind-Sonipat route in Haryana. The train produces zero carbon emissions and can run 1,000 km on a single tank. Railways Minister announced plans to convert 35 heritage routes to hydrogen power by 2030.",
            "category": "national",
            "source": "The Hindu",
            "image_url": "https://picsum.photos/seed/train/800/400",
            "mood_tag": "positive",
        },
    ]

    for i, article in enumerate(sample_articles):
        aid = hashlib.md5(
            (article["title"].lower() + f"https://example.com/{i}").encode()
        ).hexdigest()
        _mem_articles[aid] = {
            "id": aid,
            "title": article["title"],
            "source": article.get("source", sources[i % len(sources)]),
            "category": article["category"],
            "state": None,
            "image_url": article.get("image_url", f"https://picsum.photos/seed/{i}/800/400"),
            "original_link": f"https://example.com/article/{aid}",
            "published_at": datetime.now(timezone.utc) - timedelta(hours=i * 2),
            "summaries": {
                "en": {
                    "headline": article["headline"],
                    "summary": article["summary"],
                },
                "hi": {
                    "headline": f"[हिन्दी] {article['headline']}",
                    "summary": f"[हिन्दी अनुवाद] {article['summary'][:100]}...",
                },
            },
            "tts_urls": {},
            "is_trending": i < 5,
            "mood_tag": article.get("mood_tag", "neutral"),
            "language": "en",
            "saved_at": datetime.now(timezone.utc),
        }

    logger.info("Seeded %d demo articles", len(_mem_articles))


# ─── Firebase Init ────────────────────────────────────────────────────────────

def init_firebase(credentials_path):
    """Initialize Firebase Admin SDK with a service account JSON file."""
    global _db, _bucket, _demo_mode
    try:
        import firebase_admin
        from firebase_admin import credentials as fb_credentials, firestore, storage

        cred = fb_credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred, {
            "storageBucket": f"{cred.project_id}.appspot.com",
        })
        _db = firestore.client()
        _bucket = storage.bucket()

        _demo_mode = False
        logger.info("Firebase initialized successfully for project: %s", cred.project_id)
        return True
    except Exception as e:
        logger.error("Failed to initialize Firebase: %s", e)
        logger.info("Falling back to DEMO mode with sample data.")
        _demo_mode = True
        _seed_demo_data()
        return False


def is_demo_mode():
    return _demo_mode


def ensure_demo_seeded():
    """No longer seeds demo data — real RSS articles are fetched on startup."""
    pass


def _get_db():
    if _demo_mode:
        return None
    if _db is None:
        raise RuntimeError("Firebase not initialized. Call init_firebase() first.")
    return _db


def _get_bucket():
    if _demo_mode:
        return None
    if _bucket is None:
        raise RuntimeError("Firebase not initialized. Call init_firebase() first.")
    return _bucket


# ─── Articles ────────────────────────────────────────────────────────────────

def save_article(article_data):
    """Save an article document to the 'articles' collection."""
    if _demo_mode:
        aid = article_data.get("id", str(uuid.uuid4()))
        article_data["id"] = aid
        article_data["saved_at"] = datetime.now(timezone.utc)
        _mem_articles[aid] = article_data
        return aid
    try:
        from firebase_admin import firestore
        db = _get_db()
        article_id = article_data.get("id")
        if not article_id:
            logger.warning("Article data missing 'id' field, skipping save.")
            return None
        article_data["saved_at"] = firestore.SERVER_TIMESTAMP
        db.collection("articles").document(article_id).set(article_data, merge=True)
        logger.debug("Saved article: %s", article_id)
        return article_id
    except Exception as e:
        logger.error("Error saving article: %s", e)
        return None


def article_exists(article_id):
    """Check whether an article already exists by its MD5 hash ID."""
    if _demo_mode:
        return article_id in _mem_articles
    try:
        db = _get_db()
        doc = db.collection("articles").document(article_id).get()
        return doc.exists
    except Exception as e:
        logger.error("Error checking article existence: %s", e)
        return False


def get_articles(language=None, category=None, state=None, limit=20, last_doc=None):
    """
    Fetch articles with optional filters, paginated.
    Returns (list_of_articles, last_document_snapshot).
    """
    if _demo_mode:
        ensure_demo_seeded()
        articles = list(_mem_articles.values())
        if language:
            articles = [a for a in articles if a.get("language") == language]
        if category and category != "all":
            articles = [a for a in articles if a.get("category") == category]
        if state:
            state_filtered = [a for a in articles if a.get("state") == state]
            if state_filtered:
                articles = state_filtered
        # Full random shuffle so every open feels completely different
        import random
        random.shuffle(articles)
        # Pagination
        page = int(last_doc) if last_doc else 0
        start = page * limit
        return articles[start:start + limit], None

    try:
        from firebase_admin import firestore
        db = _get_db()
        query = db.collection("articles")

        if language:
            query = query.where("language", "==", language)
        if category and category != "all":
            query = query.where("category", "==", category)
        if state:
            query = query.where("state", "==", state)

        query = query.order_by("published_at", direction=firestore.Query.DESCENDING)

        if last_doc:
            query = query.start_after(last_doc)

        query = query.limit(limit)
        docs = query.stream()

        articles = []
        last_snapshot = None
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            articles.append(data)
            last_snapshot = doc

        return articles, last_snapshot
    except Exception as e:
        logger.error("Error fetching articles: %s", e)
        return [], None


def get_article_by_id(article_id):
    """Fetch a single article by ID."""
    if _demo_mode:
        return _mem_articles.get(article_id)
    try:
        db = _get_db()
        doc = db.collection("articles").document(article_id).get()
        if doc.exists:
            data = doc.to_dict()
            data["id"] = doc.id
            return data
        return None
    except Exception as e:
        logger.error("Error fetching article %s: %s", article_id, e)
        return None


def update_tts_url(article_id, language, url):
    """Store a TTS audio URL for an article in a given language."""
    if _demo_mode:
        if article_id in _mem_articles:
            _mem_articles[article_id].setdefault("tts_urls", {})[language] = url
        return
    try:
        db = _get_db()
        db.collection("articles").document(article_id).update({
            f"tts_urls.{language}": url,
        })
        logger.debug("Updated TTS URL for %s [%s]", article_id, language)
    except Exception as e:
        logger.error("Error updating TTS URL: %s", e)


def get_trending_articles(language=None, limit=50):
    """Get trending (most recent) articles, optionally filtered by language."""
    if _demo_mode:
        ensure_demo_seeded()
        articles = [a for a in _mem_articles.values() if a.get("is_trending")]
        articles.sort(key=lambda a: a.get("published_at", datetime.min.replace(tzinfo=timezone.utc)), reverse=True)
        return articles[:limit]
    try:
        from firebase_admin import firestore
        db = _get_db()
        query = db.collection("articles")
        if language:
            query = query.where("language", "==", language)
        query = (
            query.order_by("published_at", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )
        docs = query.stream()
        articles = []
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            articles.append(data)
        return articles
    except Exception as e:
        logger.error("Error fetching trending articles: %s", e)
        return []


def get_article_stats():
    """Return aggregate counts by category, language, and date."""
    if _demo_mode:
        ensure_demo_seeded()
        stats = {"by_category": {}, "by_language": {}, "total": len(_mem_articles)}
        for a in _mem_articles.values():
            cat = a.get("category", "unknown")
            lang = a.get("language", "unknown")
            stats["by_category"][cat] = stats["by_category"].get(cat, 0) + 1
            stats["by_language"][lang] = stats["by_language"].get(lang, 0) + 1
        return stats
    try:
        db = _get_db()
        docs = db.collection("articles").stream()
        stats = {"by_category": {}, "by_language": {}, "total": 0}
        for doc in docs:
            data = doc.to_dict()
            stats["total"] += 1
            cat = data.get("category", "unknown")
            lang = data.get("language", "unknown")
            stats["by_category"][cat] = stats["by_category"].get(cat, 0) + 1
            stats["by_language"][lang] = stats["by_language"].get(lang, 0) + 1
        return stats
    except Exception as e:
        logger.error("Error fetching article stats: %s", e)
        return {"by_category": {}, "by_language": {}, "total": 0}


def cleanup_old_articles(max_age_days=7):
    """Delete articles older than max_age_days."""
    if _demo_mode:
        return 0
    try:
        from firebase_admin import firestore
        db = _get_db()
        cutoff = datetime.now(timezone.utc) - timedelta(days=max_age_days)
        old_docs = (
            db.collection("articles")
            .where("published_at", "<", cutoff)
            .stream()
        )
        batch = db.batch()
        count = 0
        for doc in old_docs:
            batch.delete(doc.reference)
            count += 1
            if count % 400 == 0:
                batch.commit()
                batch = db.batch()
        if count % 400 != 0:
            batch.commit()
        logger.info("Cleaned up %d old articles", count)
        return count
    except Exception as e:
        logger.error("Error cleaning up old articles: %s", e)
        return 0


# ─── Users ───────────────────────────────────────────────────────────────────

def save_user(user_data):
    """Create or update a user document."""
    if _demo_mode:
        uid = user_data.get("uid", str(uuid.uuid4()))
        user_data["uid"] = uid
        _mem_users[uid] = user_data
        return uid
    try:
        from firebase_admin import firestore
        db = _get_db()
        uid = user_data.get("uid")
        if not uid:
            return None
        user_data["updated_at"] = firestore.SERVER_TIMESTAMP
        db.collection("users").document(uid).set(user_data, merge=True)
        return uid
    except Exception as e:
        logger.error("Error saving user: %s", e)
        return None


def get_user(uid):
    """Fetch a user by UID."""
    if _demo_mode:
        return _mem_users.get(uid)
    try:
        db = _get_db()
        doc = db.collection("users").document(uid).get()
        if doc.exists:
            return doc.to_dict()
        return None
    except Exception as e:
        logger.error("Error fetching user %s: %s", uid, e)
        return None


def update_user_prefs(uid, prefs):
    """Update user preferences (language, categories, state, etc.)."""
    if _demo_mode:
        if uid in _mem_users:
            _mem_users[uid]["preferences"] = prefs
        return True
    try:
        from firebase_admin import firestore
        db = _get_db()
        db.collection("users").document(uid).update({
            "preferences": prefs,
            "updated_at": firestore.SERVER_TIMESTAMP,
        })
        return True
    except Exception as e:
        logger.error("Error updating user prefs: %s", e)
        return False


def add_bookmark(uid, article_id):
    """Add an article to user's bookmarks."""
    if _demo_mode:
        if uid in _mem_users:
            _mem_users[uid].setdefault("bookmarks", []).append(article_id)
        return True
    try:
        from firebase_admin import firestore
        db = _get_db()
        db.collection("users").document(uid).update({
            "bookmarks": firestore.ArrayUnion([article_id]),
        })
        return True
    except Exception as e:
        logger.error("Error adding bookmark: %s", e)
        return False


def remove_bookmark(uid, article_id):
    """Remove an article from user's bookmarks."""
    if _demo_mode:
        if uid in _mem_users and "bookmarks" in _mem_users[uid]:
            _mem_users[uid]["bookmarks"] = [
                b for b in _mem_users[uid]["bookmarks"] if b != article_id
            ]
        return True
    try:
        from firebase_admin import firestore
        db = _get_db()
        db.collection("users").document(uid).update({
            "bookmarks": firestore.ArrayRemove([article_id]),
        })
        return True
    except Exception as e:
        logger.error("Error removing bookmark: %s", e)
        return False


def get_bookmarks(uid):
    """Get all bookmarked article IDs for a user."""
    if _demo_mode:
        user = _mem_users.get(uid)
        if not user:
            return []
        return [_mem_articles[aid] for aid in user.get("bookmarks", []) if aid in _mem_articles]
    try:
        user = get_user(uid)
        if not user:
            return []
        bookmark_ids = user.get("bookmarks", [])
        if not bookmark_ids:
            return []
        db = _get_db()
        articles = []
        for aid in bookmark_ids:
            doc = db.collection("articles").document(aid).get()
            if doc.exists:
                data = doc.to_dict()
                data["id"] = doc.id
                articles.append(data)
        return articles
    except Exception as e:
        logger.error("Error fetching bookmarks for %s: %s", uid, e)
        return []


# ─── Quiz ────────────────────────────────────────────────────────────────────

def save_quiz(quiz_data):
    """Save a daily quiz document."""
    if _demo_mode:
        date_str = quiz_data.get("date", datetime.now(timezone.utc).strftime("%Y-%m-%d"))
        _mem_quizzes[date_str] = quiz_data
        return date_str
    try:
        from firebase_admin import firestore
        db = _get_db()
        date_str = quiz_data.get("date", datetime.now(timezone.utc).strftime("%Y-%m-%d"))
        quiz_data["created_at"] = firestore.SERVER_TIMESTAMP
        db.collection("quizzes").document(date_str).set(quiz_data)
        logger.info("Saved quiz for date: %s", date_str)
        return date_str
    except Exception as e:
        logger.error("Error saving quiz: %s", e)
        return None


def get_today_quiz():
    """Get today's quiz."""
    if _demo_mode:
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        if today in _mem_quizzes:
            return _mem_quizzes[today]
        # Return a demo quiz
        return {
            "date": today,
            "questions": [
                {
                    "question": "Which organization launched the Gaganyaan unmanned test mission?",
                    "options": ["NASA", "ISRO", "ESA", "CNSA"],
                    "correct_index": 1,
                },
                {
                    "question": "What milestone did UPI transactions cross in March 2026?",
                    "options": ["5 billion", "10 billion", "20 billion", "50 billion"],
                    "correct_index": 2,
                },
                {
                    "question": "Which index crossed the 85,000 mark?",
                    "options": ["Nifty50", "Sensex", "NASDAQ", "FTSE"],
                    "correct_index": 1,
                },
                {
                    "question": "India's first hydrogen-powered train runs on which route?",
                    "options": ["Delhi-Agra", "Jind-Sonipat", "Mumbai-Pune", "Chennai-Bangalore"],
                    "correct_index": 1,
                },
                {
                    "question": "Which AI startup raised 1 billion dollars in funding?",
                    "options": ["Krutrim", "Infosys AI", "Wipro ML", "TCS Neural"],
                    "correct_index": 0,
                },
            ],
        }
    try:
        db = _get_db()
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        doc = db.collection("quizzes").document(today).get()
        if doc.exists:
            return doc.to_dict()
        return None
    except Exception as e:
        logger.error("Error fetching today's quiz: %s", e)
        return None


# ─── FCM Tokens ──────────────────────────────────────────────────────────────

def save_fcm_token(uid, token):
    """Store an FCM token for a user."""
    if _demo_mode:
        if uid in _mem_users:
            _mem_users[uid]["fcm_token"] = token
        return True
    try:
        from firebase_admin import firestore
        db = _get_db()
        db.collection("users").document(uid).update({
            "fcm_token": token,
            "updated_at": firestore.SERVER_TIMESTAMP,
        })
        return True
    except Exception as e:
        logger.error("Error saving FCM token: %s", e)
        return False


# ─── Feedback ────────────────────────────────────────────────────────────────

def save_feedback(feedback_data):
    """Save user feedback (e.g., bad translation report)."""
    if _demo_mode:
        feedback_data["created_at"] = datetime.now(timezone.utc).isoformat()
        _mem_feedback.append(feedback_data)
        return True
    try:
        from firebase_admin import firestore
        db = _get_db()
        feedback_data["created_at"] = firestore.SERVER_TIMESTAMP
        db.collection("feedback").add(feedback_data)
        return True
    except Exception as e:
        logger.error("Error saving feedback: %s", e)
        return False
