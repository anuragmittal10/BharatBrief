"""
BharatBrief Admin Panel
Flask-based admin interface for managing the news aggregation platform.
"""

import os
import sys
import json
import uuid
from datetime import datetime, timedelta, timezone
from functools import wraps

from flask import (
    Flask, render_template, request, redirect, url_for,
    flash, session, jsonify, abort
)

# Add backend to path so we can import shared services
BACKEND_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'backend')
sys.path.insert(0, BACKEND_DIR)

# ---------------------------------------------------------------------------
# Firebase initialisation (shared with backend)
# ---------------------------------------------------------------------------
try:
    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        cred_path = os.environ.get(
            'GOOGLE_APPLICATION_CREDENTIALS',
            os.path.join(BACKEND_DIR, 'config', 'serviceAccountKey.json'),
        )
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            firebase_admin.initialize_app()

    db = firestore.client()
    FIREBASE_AVAILABLE = True
except Exception as exc:
    print(f"[admin] Firebase unavailable – running in demo mode: {exc}")
    db = None
    FIREBASE_AVAILABLE = False

# ---------------------------------------------------------------------------
# Flask app
# ---------------------------------------------------------------------------
app = Flask(__name__)
app.secret_key = os.environ.get('ADMIN_SECRET_KEY', 'bharatbrief-admin-secret-change-me')
ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'admin123')

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def login_required(f):
    """Decorator – redirect to /login when not authenticated."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('admin_logged_in'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated


def _ts(dt_obj):
    """Convert a Firestore timestamp / datetime to ISO string."""
    if dt_obj is None:
        return None
    if hasattr(dt_obj, 'isoformat'):
        return dt_obj.isoformat()
    return str(dt_obj)


def _collection_count(collection_name):
    """Return the number of documents in a Firestore collection."""
    if not FIREBASE_AVAILABLE:
        return 0
    try:
        docs = db.collection(collection_name).select([]).stream()
        return sum(1 for _ in docs)
    except Exception:
        return 0


def _get_docs(collection, limit=100, order_by=None, direction=None, filters=None):
    """Generic Firestore query helper. Returns list of dicts with 'id' key."""
    if not FIREBASE_AVAILABLE:
        return []
    try:
        ref = db.collection(collection)
        if filters:
            for field, op, val in filters:
                ref = ref.where(field, op, val)
        if order_by:
            from google.cloud.firestore_v1 import Query
            dir_ = Query.DESCENDING if direction == 'desc' else Query.ASCENDING
            ref = ref.order_by(order_by, direction=dir_)
        if limit:
            ref = ref.limit(limit)
        return [{**doc.to_dict(), 'id': doc.id} for doc in ref.stream()]
    except Exception as e:
        print(f"[admin] Firestore query error ({collection}): {e}")
        return []


def _get_doc(collection, doc_id):
    """Return a single document dict or None."""
    if not FIREBASE_AVAILABLE:
        return None
    try:
        doc = db.collection(collection).document(doc_id).get()
        if doc.exists:
            return {**doc.to_dict(), 'id': doc.id}
    except Exception as e:
        print(f"[admin] Firestore get error ({collection}/{doc_id}): {e}")
    return None


def _update_doc(collection, doc_id, data):
    if not FIREBASE_AVAILABLE:
        return False
    try:
        db.collection(collection).document(doc_id).update(data)
        return True
    except Exception as e:
        print(f"[admin] Firestore update error: {e}")
        return False


def _set_doc(collection, doc_id, data):
    if not FIREBASE_AVAILABLE:
        return False
    try:
        db.collection(collection).document(doc_id).set(data)
        return True
    except Exception as e:
        print(f"[admin] Firestore set error: {e}")
        return False


def _delete_doc(collection, doc_id):
    if not FIREBASE_AVAILABLE:
        return False
    try:
        db.collection(collection).document(doc_id).delete()
        return True
    except Exception as e:
        print(f"[admin] Firestore delete error: {e}")
        return False


# ---------------------------------------------------------------------------
# Auth routes
# ---------------------------------------------------------------------------

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        password = request.form.get('password', '')
        if password == ADMIN_PASSWORD:
            session['admin_logged_in'] = True
            flash('Logged in successfully.', 'success')
            return redirect(url_for('dashboard'))
        flash('Invalid password.', 'danger')
    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out.', 'info')
    return redirect(url_for('login'))


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

@app.route('/')
@login_required
def dashboard():
    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    total_articles = _collection_count('articles')
    today_articles = len(_get_docs('articles', limit=500, filters=[
        ('published_at', '>=', today),
    ])) if FIREBASE_AVAILABLE else 0
    active_feeds = _collection_count('feeds')
    total_users = _collection_count('users')

    recent_articles = _get_docs('articles', limit=20, order_by='published_at', direction='desc')
    feeds = _get_docs('feeds', limit=50)

    # Articles per day (last 7 days)
    articles_per_day = {}
    for i in range(7):
        day = today - timedelta(days=i)
        articles_per_day[day.strftime('%b %d')] = 0
    for art in _get_docs('articles', limit=1000, filters=[
        ('published_at', '>=', today - timedelta(days=7)),
    ]):
        pub = art.get('published_at')
        if pub and hasattr(pub, 'strftime'):
            key = pub.strftime('%b %d')
            articles_per_day[key] = articles_per_day.get(key, 0) + 1

    chart_labels = list(reversed(list(articles_per_day.keys())))
    chart_data = list(reversed(list(articles_per_day.values())))

    return render_template('dashboard.html',
                           total_articles=total_articles,
                           today_articles=today_articles,
                           active_feeds=active_feeds,
                           total_users=total_users,
                           recent_articles=recent_articles,
                           feeds=feeds,
                           chart_labels=json.dumps(chart_labels),
                           chart_data=json.dumps(chart_data))


# ---------------------------------------------------------------------------
# Articles
# ---------------------------------------------------------------------------

@app.route('/articles')
@login_required
def articles():
    category = request.args.get('category', '')
    language = request.args.get('language', '')
    status = request.args.get('status', '')
    search = request.args.get('search', '')
    page = int(request.args.get('page', 1))
    per_page = 25

    filters = []
    if category:
        filters.append(('category', '==', category))
    if language:
        filters.append(('language', '==', language))
    if status == 'flagged':
        filters.append(('flagged', '==', True))
    if status == 'trending':
        filters.append(('trending', '==', True))

    all_articles = _get_docs('articles', limit=500, order_by='published_at',
                             direction='desc', filters=filters or None)

    if search:
        search_lower = search.lower()
        all_articles = [a for a in all_articles
                        if search_lower in (a.get('title', '') or '').lower()
                        or search_lower in (a.get('source', '') or '').lower()]

    total = len(all_articles)
    total_pages = max(1, (total + per_page - 1) // per_page)
    page = min(page, total_pages)
    paginated = all_articles[(page - 1) * per_page: page * per_page]

    categories = sorted({a.get('category', '') for a in all_articles if a.get('category')})
    languages = sorted({a.get('language', '') for a in all_articles if a.get('language')})

    return render_template('articles.html',
                           articles=paginated,
                           categories=categories,
                           languages=languages,
                           current_category=category,
                           current_language=language,
                           current_status=status,
                           search=search,
                           page=page,
                           total_pages=total_pages,
                           total=total)


@app.route('/articles/<article_id>')
@login_required
def article_detail(article_id):
    article = _get_doc('articles', article_id)
    if not article:
        abort(404)

    translations = _get_docs('translations', limit=50, filters=[
        ('article_id', '==', article_id),
    ])

    return render_template('article_detail.html',
                           article=article,
                           translations=translations)


@app.route('/articles/<article_id>/moderate', methods=['POST'])
@login_required
def moderate_article(article_id):
    action = request.form.get('action', '')
    updates = {'moderated_at': datetime.now(timezone.utc), 'moderated_by': 'admin'}

    if action == 'approve':
        updates['status'] = 'approved'
        updates['flagged'] = False
    elif action == 'reject':
        updates['status'] = 'rejected'
    elif action == 'flag':
        updates['flagged'] = True
    elif action == 'delete':
        _delete_doc('articles', article_id)
        flash('Article deleted.', 'warning')
        return redirect(url_for('articles'))
    else:
        flash('Unknown moderation action.', 'danger')
        return redirect(url_for('article_detail', article_id=article_id))

    _update_doc('articles', article_id, updates)
    flash(f'Article {action}d.', 'success')
    return redirect(url_for('article_detail', article_id=article_id))


# ---------------------------------------------------------------------------
# Feeds
# ---------------------------------------------------------------------------

@app.route('/feeds')
@login_required
def feeds():
    all_feeds = _get_docs('feeds', limit=200)
    return render_template('feeds.html', feeds=all_feeds)


@app.route('/feeds', methods=['POST'])
@login_required
def add_feed():
    data = {
        'name': request.form.get('name', '').strip(),
        'url': request.form.get('url', '').strip(),
        'category': request.form.get('category', '').strip(),
        'language': request.form.get('language', 'en').strip(),
        'state': request.form.get('state', '').strip(),
        'active': True,
        'last_fetch': None,
        'error_count': 0,
        'created_at': datetime.now(timezone.utc),
    }
    if not data['name'] or not data['url']:
        flash('Name and URL are required.', 'danger')
        return redirect(url_for('feeds'))

    doc_id = str(uuid.uuid4())[:12]
    _set_doc('feeds', doc_id, data)
    flash(f'Feed "{data["name"]}" added.', 'success')
    return redirect(url_for('feeds'))


@app.route('/feeds/<feed_id>', methods=['PUT'])
@login_required
def edit_feed(feed_id):
    data = request.get_json(silent=True) or {}
    allowed = {'name', 'url', 'category', 'language', 'state', 'active'}
    updates = {k: v for k, v in data.items() if k in allowed}
    if updates:
        _update_doc('feeds', feed_id, updates)
    return jsonify({'ok': True})


@app.route('/feeds/<feed_id>', methods=['DELETE'])
@login_required
def delete_feed(feed_id):
    _delete_doc('feeds', feed_id)
    return jsonify({'ok': True, 'message': 'Feed deleted.'})


@app.route('/feeds/test', methods=['POST'])
@login_required
def test_feed():
    url = request.json.get('url', '') if request.is_json else request.form.get('url', '')
    if not url:
        return jsonify({'ok': False, 'error': 'URL is required.'}), 400

    try:
        import feedparser
        feed = feedparser.parse(url)
        entries = []
        for entry in feed.entries[:5]:
            entries.append({
                'title': getattr(entry, 'title', ''),
                'link': getattr(entry, 'link', ''),
                'published': getattr(entry, 'published', ''),
            })
        return jsonify({
            'ok': True,
            'feed_title': feed.feed.get('title', 'Unknown'),
            'entry_count': len(feed.entries),
            'sample_entries': entries,
        })
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500


# ---------------------------------------------------------------------------
# Quiz
# ---------------------------------------------------------------------------

@app.route('/quiz')
@login_required
def quiz():
    today_str = datetime.now(timezone.utc).strftime('%Y-%m-%d')
    quiz_doc = _get_doc('quizzes', today_str)
    questions = quiz_doc.get('questions', []) if quiz_doc else []

    stats = {
        'participation': quiz_doc.get('participation_count', 0) if quiz_doc else 0,
        'avg_score': quiz_doc.get('avg_score', 0) if quiz_doc else 0,
    }

    return render_template('quiz.html', questions=questions, stats=stats,
                           quiz_date=today_str)


@app.route('/quiz/generate', methods=['POST'])
@login_required
def generate_quiz():
    try:
        from services.quiz_service import generate_daily_quiz
        result = generate_daily_quiz()
        flash('Quiz generated successfully.', 'success')
        return jsonify({'ok': True, 'message': 'Quiz generated.'})
    except ImportError:
        flash('Quiz service not available.', 'warning')
        return jsonify({'ok': False, 'error': 'Quiz service not available.'}), 500
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500


# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------

@app.route('/notifications')
@login_required
def notifications():
    sent = _get_docs('notifications', limit=50, order_by='sent_at', direction='desc')
    return render_template('notifications.html', notifications=sent)


@app.route('/notifications/send', methods=['POST'])
@login_required
def send_notification():
    data = {
        'title': request.form.get('title', '').strip(),
        'body': request.form.get('body', '').strip(),
        'topic': request.form.get('topic', 'all').strip(),
        'sent_at': datetime.now(timezone.utc),
        'sent_by': 'admin',
    }
    if not data['title']:
        flash('Title is required.', 'danger')
        return redirect(url_for('notifications'))

    try:
        from firebase_admin import messaging
        message = messaging.Message(
            notification=messaging.Notification(title=data['title'], body=data['body']),
            topic=data['topic'],
        )
        messaging.send(message)
        data['status'] = 'sent'
    except Exception as e:
        data['status'] = 'failed'
        data['error'] = str(e)

    doc_id = datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S') + '-' + str(uuid.uuid4())[:6]
    _set_doc('notifications', doc_id, data)
    flash(f'Notification {"sent" if data["status"] == "sent" else "failed"}.',
          'success' if data['status'] == 'sent' else 'danger')
    return redirect(url_for('notifications'))


# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------

@app.route('/users')
@login_required
def users():
    all_users = _get_docs('users', limit=200, order_by='last_active', direction='desc')
    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    active_today = sum(
        1 for u in all_users
        if u.get('last_active') and hasattr(u['last_active'], 'timestamp')
        and u['last_active'].timestamp() >= today.timestamp()
    )

    lang_dist = {}
    for u in all_users:
        lang = u.get('language', 'unknown')
        lang_dist[lang] = lang_dist.get(lang, 0) + 1

    return render_template('users.html',
                           users=all_users,
                           total_users=len(all_users),
                           active_today=active_today,
                           lang_dist=lang_dist)


# ---------------------------------------------------------------------------
# Translations
# ---------------------------------------------------------------------------

@app.route('/translations/flagged')
@login_required
def flagged_translations():
    flagged = _get_docs('translations', limit=100, filters=[
        ('flagged', '==', True),
    ])
    return render_template('translations.html', translations=flagged)


@app.route('/translations/<translation_id>/fix', methods=['POST'])
@login_required
def fix_translation(translation_id):
    new_text = request.form.get('text', '').strip()
    if not new_text:
        flash('Translation text cannot be empty.', 'danger')
        return redirect(url_for('flagged_translations'))

    _update_doc('translations', translation_id, {
        'translated_text': new_text,
        'flagged': False,
        'manually_fixed': True,
        'fixed_at': datetime.now(timezone.utc),
        'fixed_by': 'admin',
    })
    flash('Translation updated.', 'success')
    return redirect(url_for('flagged_translations'))


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

@app.route('/pipeline/run', methods=['POST'])
@login_required
def run_pipeline():
    try:
        from services.pipeline_service import run_full_pipeline
        result = run_full_pipeline()
        return jsonify({'ok': True, 'message': 'Pipeline completed.', 'result': str(result)})
    except ImportError:
        return jsonify({'ok': False, 'error': 'Pipeline service not available. Check backend/services/pipeline_service.py'}), 500
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

@app.route('/settings', methods=['GET'])
@login_required
def settings():
    config = _get_doc('config', 'app_settings') or {
        'fetch_interval': 30,
        'max_article_age': 48,
        'gemini_batch_size': 10,
        'tts_pre_generate': True,
        'feeds_enabled': True,
    }
    return render_template('settings.html', config=config)


@app.route('/settings', methods=['POST'])
@login_required
def update_settings():
    data = {
        'fetch_interval': int(request.form.get('fetch_interval', 30)),
        'max_article_age': int(request.form.get('max_article_age', 48)),
        'gemini_batch_size': int(request.form.get('gemini_batch_size', 10)),
        'tts_pre_generate': request.form.get('tts_pre_generate') == 'on',
        'feeds_enabled': request.form.get('feeds_enabled') == 'on',
        'updated_at': datetime.now(timezone.utc),
    }
    _set_doc('config', 'app_settings', data)
    flash('Settings saved.', 'success')
    return redirect(url_for('settings'))


# ---------------------------------------------------------------------------
# API endpoints for AJAX
# ---------------------------------------------------------------------------

@app.route('/api/stats')
@login_required
def api_stats():
    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    return jsonify({
        'total_articles': _collection_count('articles'),
        'today_articles': len(_get_docs('articles', limit=500, filters=[
            ('published_at', '>=', today),
        ])),
        'active_feeds': _collection_count('feeds'),
        'total_users': _collection_count('users'),
    })


# ---------------------------------------------------------------------------
# Template filters
# ---------------------------------------------------------------------------

@app.template_filter('timeago')
def timeago_filter(dt):
    if not dt or not hasattr(dt, 'timestamp'):
        return 'N/A'
    diff = datetime.now(timezone.utc) - dt
    seconds = int(diff.total_seconds())
    if seconds < 60:
        return f'{seconds}s ago'
    minutes = seconds // 60
    if minutes < 60:
        return f'{minutes}m ago'
    hours = minutes // 60
    if hours < 24:
        return f'{hours}h ago'
    days = hours // 24
    return f'{days}d ago'


@app.template_filter('dtformat')
def dtformat_filter(dt, fmt='%b %d, %Y %H:%M'):
    if not dt or not hasattr(dt, 'strftime'):
        return 'N/A'
    return dt.strftime(fmt)


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

if __name__ == '__main__':
    app.run(debug=True, port=5001)
