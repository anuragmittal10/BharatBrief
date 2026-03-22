# BharatBrief - Project Documentation

> Last updated: 2026-03-23

---

## 1. Project Overview

**BharatBrief** is an AI-powered, multilingual news aggregator for India, inspired by the Inshorts app. It delivers concise, 60-word news summaries in 13 Indian languages via a swipeable card-based mobile and web interface.

**Problem:** India has 900M+ internet users, but a large majority lack access to quality news in their native language. Existing English-centric news apps leave out hundreds of millions of vernacular readers.

**Solution:** BharatBrief aggregates news from 43+ RSS feeds across major Indian and international publishers, uses Google Gemini AI to generate concise summaries, and translates them into 13 Indian languages using the government-backed Bhashini (ULCA) translation platform.

**Owner:** Tanishq Bajaj (solopreneur)

**GitHub:** [https://github.com/anuragmittal10/BharatBrief](https://github.com/anuragmittal10/BharatBrief)

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.x (cross-platform: Android, iOS, Web, macOS) |
| **Backend** | Python / Flask REST API |
| **Admin Panel** | Flask web app (planned) |
| **Database** | Firebase Firestore (currently running in demo/in-memory mode) |
| **Storage** | Firebase Cloud Storage (for TTS audio files) |
| **AI Summarization** | Google Gemini 2.0 Flash (`gemini-1.5-flash` model) |
| **Translation** | Bhashini API (ULCA - Indian government translation platform) |
| **Text-to-Speech** | Bhashini TTS |
| **Monetization** | Google AdMob (test IDs configured, not yet live) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Hosting** | Railway.app (backend), GitHub (source) |
| **Scheduler** | APScheduler (BackgroundScheduler) |
| **State Management** | Provider (Flutter) |

### Key Dependencies

**Backend (`requirements.txt`):**
- `flask==3.1.0` / `flask-cors==5.0.0`
- `feedparser==6.0.11`
- `google-generativeai==0.8.3`
- `firebase-admin==6.6.0`
- `APScheduler==3.10.4`
- `requests==2.32.3`
- `python-dotenv==1.0.1`
- `gunicorn==21.2.0`

**Flutter (`pubspec.yaml`):**
- `provider: ^6.1.5+1` (state management)
- `http: ^1.6.0` (API calls)
- `shared_preferences: ^2.5.4` (local storage)
- `audioplayers: ^6.6.0` (TTS playback)
- `cached_network_image: ^3.4.1`
- `shimmer: ^3.0.0` (loading skeletons)
- `share_plus: ^12.0.1`
- `url_launcher: ^6.3.2`
- `connectivity_plus: ^7.0.0`
- `google_fonts: ^8.0.2`

> Firebase SDK and AdMob SDK are commented out in `pubspec.yaml` pending configuration.

---

## 3. Architecture

### Full Pipeline (target state)

```
RSS Feeds (43+)
    |
    v
[RSS Service] -- fetch_all_feeds() via feedparser
    |
    v
filter_old_articles (max 48h)
    |
    v
deduplicate (title similarity check)
    |
    v
[Gemini Service] -- summarize_batch() -> 60-word summaries
    |
    v
[Bhashini Service] -- translate_article_to_all_languages() -> 13 languages
    |
    v
[Firebase Service] -- save_article() -> Firestore
    |
    v
Flutter App <-- REST API <-- Firestore / In-memory store
```

### Lightweight Pipeline (current state)

Since Gemini API and Bhashini are not yet configured, the app runs a simplified pipeline:

```
RSS Feeds (43+)
    |
    v
[RSS Service] -- fetch_all_feeds()
    |
    v
filter_old_articles (max 72h)
    |
    v
deduplicate
    |
    v
Use RSS title as headline, truncated description as summary (no AI)
    |
    v
[Firebase Service] -- save_article() -> In-memory store
    |
    v
Flutter App <-- REST API <-- In-memory store
```

### Scheduling

- **APScheduler** is configured to run `fetch_and_process()` every 15 minutes (configurable via `FETCH_INTERVAL_MINUTES` env var).
- **Auto-fetch on startup:** The first HTTP request to the backend triggers a one-time lightweight RSS fetch in a background thread.
- The scheduler service also supports cron-based triggers for quiz generation and article archival.

### Data Model (Article)

Each article stored in Firestore / in-memory has this structure:

```json
{
  "id": "md5_hash",
  "title": "Original RSS title",
  "source": "NDTV",
  "category": "national",
  "state": "MH",
  "image_url": "https://...",
  "original_link": "https://...",
  "published_at": "2026-03-23T10:00:00+00:00",
  "summaries": {
    "en": { "headline": "...", "summary": "..." },
    "hi": { "headline": "...", "summary": "..." }
  },
  "tts_urls": {
    "en": "https://storage.googleapis.com/..."
  },
  "is_trending": true,
  "mood_tag": "neutral",
  "language": "en"
}
```

---

## 4. Backend API

**Base URL:** `https://bharatbrief-production.up.railway.app`

### Endpoints

#### Health

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/health` | Health check. Returns `{ "status": "ok", "timestamp": "..." }` |

#### Articles

| Method | Path | Query Params | Description |
|---|---|---|---|
| `GET` | `/api/articles` | `lang` (default: `en`), `category` (default: `all`), `state`, `limit` (default: 20, max: 100) | Fetch paginated articles with optional filters |
| `GET` | `/api/articles/<id>` | -- | Get a single article by ID |
| `GET` | `/api/articles/<id>/deep` | -- | Get an extended AI deep-dive summary (requires Gemini) |

**Example:**
```
GET /api/articles?lang=hi&category=national&state=MH&limit=20
```

**Response:**
```json
{
  "success": true,
  "count": 20,
  "articles": [ ... ]
}
```

#### Trending

| Method | Path | Query Params | Description |
|---|---|---|---|
| `GET` | `/api/trending` | `lang` (default: `en`), `limit` (default: 50, max: 100) | Get trending articles |

#### TTS (Text-to-Speech)

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/tts/<article_id>/<lang>` | Get or generate TTS audio URL for an article in the given language |

#### Manual Fetch

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/trigger-fetch` | Manually trigger a lightweight RSS fetch in the background |

#### Quiz

| Method | Path | Body | Description |
|---|---|---|---|
| `GET` | `/api/quiz/today` | -- | Get today's news quiz |
| `POST` | `/api/quiz/submit` | `{ "uid": "...", "answers": [0,1,2,3,1], "score": 4 }` | Submit quiz answers |

#### User

| Method | Path | Body | Description |
|---|---|---|---|
| `POST` | `/api/user/register` | `{ "uid": "...", "preferences": { "language": "en", "categories": ["all"], "state": null } }` | Register an anonymous user |
| `PUT` | `/api/user/<uid>/preferences` | `{ "language": "hi", "categories": [...], "state": "MH" }` | Update user preferences |
| `GET` | `/api/user/<uid>/bookmarks` | -- | Get user's bookmarked articles |
| `POST` | `/api/user/<uid>/bookmarks/<article_id>` | -- | Add a bookmark |
| `DELETE` | `/api/user/<uid>/bookmarks/<article_id>` | -- | Remove a bookmark |
| `POST` | `/api/user/fcm-token` | `{ "uid": "...", "token": "...", "language": "en", "topics": [...] }` | Register FCM push notification token |

#### Configuration

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/languages` | Get list of all 13 supported languages |
| `GET` | `/api/categories` | Get list of all news categories |

#### Feedback

| Method | Path | Body | Description |
|---|---|---|---|
| `POST` | `/api/feedback` | `{ "article_id": "...", "language": "hi", "type": "bad_translation", "message": "...", "uid": "..." }` | Submit feedback (bad translation, etc.) |

#### Stats

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/stats` | Get article statistics (admin) |

---

## 5. RSS Feeds

BharatBrief ingests from **43+ RSS feeds** across 10 categories and 12 regional states/UTs.

### By Category

| Category | # Feeds | Key Sources |
|---|---|---|
| **National** | 10 | NDTV, Times of India, The Hindu, Indian Express, Hindustan Times, News18, Amar Ujala, Navbharat Times, Dainik Jagran, Live Hindustan |
| **World** | 6 | Reuters, BBC World, NDTV World, News18 World, BBC Hindi, Hindustan Times World |
| **Business** | 5 | Business Standard, Economic Times, Moneycontrol, Livemint, NDTV Profit |
| **Sports** | 5 | ESPN Cricinfo, Cricbuzz, NDTV Sports, TOI Sports, News18 Sports |
| **Tech** | 4 | Gadgets360, Firstpost Tech, Indian Express Tech, TOI Tech |
| **Entertainment** | 4 | Bollywood Hungama, Filmfare, TOI Entertainment, News18 Entertainment |
| **Science** | 3 | ScienceDaily, TOI Science, Indian Express Science |
| **Health** | 3 | TOI Health, Indian Express Health, News18 Health |

### Regional / State Feeds

| State | Sources | Language |
|---|---|---|
| Tamil Nadu | Dinamalar, Daily Thanthi | Tamil |
| Andhra Pradesh | Eenadu | Telugu |
| Telangana | Sakshi | Telugu |
| Karnataka | Prajavani | Kannada |
| Kerala | Mathrubhumi, Manorama Online | Malayalam |
| Maharashtra | Loksatta | Marathi |
| West Bengal | Anandabazar Patrika | Bengali |
| Gujarat | Divya Bhaskar | Gujarati |
| Punjab | Ajit | Punjabi |
| Uttar Pradesh | Amar Ujala UP, Dainik Jagran UP | Hindi |
| Delhi | Live Hindustan Delhi, Amar Ujala Delhi | Hindi |
| Bihar | Dainik Jagran Bihar | Hindi |
| Rajasthan | Dainik Jagran Rajasthan | Hindi |

### Feed Processing

- **Article ID generation:** MD5 hash of `(title + link)` for deterministic deduplication.
- **Image extraction:** Tries `media:content`, `enclosure`, `og:image` from entry metadata.
- **Old article filtering:** Articles older than 72 hours (lightweight) or 48 hours (full pipeline) are discarded.
- **Deduplication:** Title similarity check to avoid near-duplicate articles from different sources.

---

## 6. Supported Languages (13)

| Code | Language | Native Name | Script |
|---|---|---|---|
| `en` | English | English | Latin |
| `hi` | Hindi | हिन्दी | Devanagari |
| `bn` | Bengali | বাংলা | Bengali |
| `te` | Telugu | తెలుగు | Telugu |
| `mr` | Marathi | मराठी | Devanagari |
| `ta` | Tamil | தமிழ் | Tamil |
| `gu` | Gujarati | ગુજરાતી | Gujarati |
| `kn` | Kannada | ಕನ್ನಡ | Kannada |
| `ml` | Malayalam | മലയാളം | Malayalam |
| `pa` | Punjabi | ਪੰਜਾਬੀ | Gurmukhi |
| `or` | Odia | ଓଡ଼ିଆ | Odia |
| `as` | Assamese | অসমীয়া | Assamese/Bengali |
| `ur` | Urdu | اردو | Nastaliq (RTL) |

The Flutter app includes full RTL support for Urdu (`textDirection: TextDirection.rtl`).

---

## 7. Flutter App Features

### Core UX
- **Inshorts-style horizontal swipe** navigation between news cards
- **Full-screen cards:** image occupies top ~40%, content bottom ~60%
- **Max-width 500px** on web for optimal reading
- **Pull to refresh** to fetch latest articles

### Navigation & Discovery
- **Category tabs:** All, National, My State, World, Sports, Tech, Business, Entertainment, Science, Health
- **Language switcher** with 13 languages
- **Trending badges** on popular articles
- **Mood indicators** (positive/negative/neutral) displayed as colored dots

### Onboarding Flow
1. **Language selection** (choose preferred language)
2. **State selection** (choose your Indian state for "My State" tab)
3. **Category preferences** (select favorite categories)

### Reading Features
- **Quick Read** mode (default 60-word summary)
- **Deep Dive** mode (extended AI-generated summary via Gemini)
- **Full Article** webview (opens original source URL)
- **Listen (TTS)** - audio playback of article summaries in selected language
- **Reading modes:** Quick Read, Deep Dive, Feel Good

### Personalization
- **Dark mode** toggle
- **Font size adjustment** (small: 0.85x, medium: 1.0x, large: 1.2x)
- **Bookmarks** - save articles for later
- **Share articles** via system share sheet

### Offline & Performance
- **Offline caching** via `shared_preferences` and local storage
- **Shimmer loading skeletons** while content loads
- **Cached network images** for faster image display
- **API timeout:** 15 seconds

### State Management
- Uses **Provider** pattern with four providers:
  - `ArticleProvider` - articles, pagination, filtering
  - `UserProvider` - user preferences, bookmarks, auth
  - `QuizProvider` - daily quiz state
  - `SettingsProvider` - theme, font size, reading mode

### Monetization (Planned)
- **AdMob** configured with test IDs:
  - Banner ads
  - Interstitial ads (every 7 cards)
  - Rewarded ads
  - Native ads
- **Poll cards** every 10 articles

---

## 8. Deployment

### Backend (Railway.app)

- **URL:** [https://bharatbrief-production.up.railway.app](https://bharatbrief-production.up.railway.app)
- **Root directory:** `/backend`
- **Runtime:** Python 3.10
- **Procfile:** `web: python run.py`
- **Auto-deploys:** On git push to `main` branch

#### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `GEMINI_API_KEY` | Yes* | -- | Google Gemini API key for AI summarization |
| `FIREBASE_CREDENTIALS_PATH` | Yes* | -- | Path to Firebase service account JSON |
| `BHASHINI_USER_ID` | No | -- | Bhashini ULCA user ID |
| `BHASHINI_API_KEY` | No | -- | Bhashini ULCA API key |
| `BHASHINI_AUTH_TOKEN` | No | -- | Bhashini compute auth token |
| `FETCH_INTERVAL_MINUTES` | No | `15` | RSS fetch interval in minutes |
| `MAX_ARTICLE_AGE_HOURS` | No | `48` | Max age of articles to keep |
| `GEMINI_BATCH_SIZE` | No | `50` | Articles per Gemini batch |
| `GEMINI_BATCH_DELAY` | No | `2` | Seconds delay between Gemini batches |
| `FLASK_HOST` | No | `0.0.0.0` | Flask bind host |
| `FLASK_PORT` | No | `8000` | Flask bind port |
| `FLASK_DEBUG` | No | `False` | Enable Flask debug mode |

> *Currently marked as required but the app gracefully falls back to demo/in-memory mode when these are missing.

### GitHub Repository

- **URL:** [https://github.com/anuragmittal10/BharatBrief](https://github.com/anuragmittal10/BharatBrief)

### Flutter APK Build

- **Build command:** `flutter build apk --debug`
- **Output:** `bharat_brief/build/app/outputs/flutter-apk/app-debug.apk`
- **Requirements:**
  - Android SDK (`android-commandlinetools`)
  - Java 17 (`openjdk@17`)
  - Flutter SDK 3.x (Dart SDK ^3.11.0)

---

## 9. Current Status & Known Issues

### Working

- Backend REST API deployed and live on Railway
- 43+ RSS feeds configured
- Lightweight pipeline: RSS fetch -> deduplicate -> save to in-memory store
- ~860 real articles fetched from working feeds
- Flutter app with full Inshorts-style UI (horizontal swipe, full-screen cards)
- All API endpoints implemented and responding
- Language and category filtering
- Auto-fetch triggers on first request after deploy

### Known Issues

| Issue | Impact | Notes |
|---|---|---|
| **Firestore API not enabled** in Firebase project (`inshortsclone-f41e7`) | Running in demo/in-memory mode | All data is stored in Python dictionaries |
| **Articles reset on Railway redeploy** | Data loss on every deploy | In-memory store is not persistent |
| **Gemini API not configured** | No AI-powered summaries | Using raw RSS title/description instead of 60-word AI summaries |
| **Bhashini translation not active** | Articles only available in source language | No cross-language translation |
| **TTS not functional** | Listen feature does not work | Requires Bhashini TTS API |
| **Some RSS feeds return errors** | Reduced article count | News18, Jagran, Live Hindustan, and some regional feeds fail |
| **No recurring scheduler on Railway** | Articles only fetched on first request | APScheduler not started on Railway; relies on auto-fetch-once |
| **Firebase SDK commented out in Flutter** | No direct Firestore/FCM in app | App uses REST API exclusively |

---

## 10. What's Done (Development Log)

### Project Setup
- Project scaffolding: Flutter app + Python backend + Flask admin panel
- GitHub repo setup and CI/CD via Railway auto-deploy

### Backend
- Flask REST API with all CRUD endpoints (articles, users, bookmarks, quiz, feedback, stats)
- RSS ingestion: 43+ feeds with feedparser, deduplication via title similarity, old article filtering
- Demo mode: full in-memory storage when Firebase credentials are unavailable
- Lazy imports: fixed 60+ second startup time by lazy-loading `google-generativeai` and `firebase-admin` SDKs
- Custom JSON provider for datetime serialization
- CORS enabled for cross-origin Flutter web requests
- Language filtering in demo mode (filter articles by source language)
- Railway deployment with auto-fetch on first request

### Flutter App
- Inshorts UI redesign: full-bleed cards, max-width 500px on web, clean typography
- Horizontal swipe (left/right) navigation between articles
- Category tabs with "My State" support
- Language switcher with 13 languages and RTL support (Urdu)
- Onboarding flow: language -> state -> category selection
- Date display on news cards
- Trending badge repositioned for better visibility
- Mood indicator dots (positive/negative/neutral)
- Dark mode support with theme switching
- Font size adjustment (small/medium/large)
- Provider-based state management (4 providers)
- Bookmarks, share, deep dive, TTS playback (UI ready)
- Shimmer loading skeletons
- Offline caching via shared_preferences

### Bug Fixes
- `dart:io` fix: removed import that broke Flutter web builds
- Audio service fix: stream controller dispose bug
- Category alignment: Flutter "tech" matched with backend "technology" -> standardized to "tech"

### Build & Deploy
- Android APK build setup (Android SDK + Java 17)
- Railway deployment configuration (Procfile, port binding)

---

## 11. Next Steps / Roadmap

### Phase 1: Core Infrastructure
- [ ] Enable Firestore API in Firebase project for persistent storage
- [ ] Set up recurring scheduler (every 10 min) on Railway
- [ ] Configure Gemini API key for AI-powered 60-word summaries
- [ ] Enable Bhashini translation pipeline for all 13 languages
- [ ] Enable Bhashini TTS for audio playback

### Phase 2: Data & Quality
- [ ] Implement article archival (7 days active, then archive to cold storage)
- [ ] Fix broken RSS feeds (News18, Jagran, Live Hindustan)
- [ ] Add more regional feeds for underserved states
- [ ] Implement quiz generation via Gemini (daily news quiz)

### Phase 3: Distribution
- [ ] Release build APK (smaller size, ProGuard, optimized)
- [ ] Google Play Store submission
- [ ] iOS build and App Store submission
- [ ] Custom domain for API (e.g., `api.bharatbrief.in`)

### Phase 4: Monetization & Growth
- [ ] AdMob integration with real ad unit IDs
- [ ] Push notifications via FCM (morning/evening digest, breaking news)
- [ ] Admin panel deployment for content moderation
- [ ] Analytics and monitoring (Firebase Analytics, error tracking)

---

## 12. Local Development Setup

### Prerequisites

- Python 3.10+
- Flutter SDK 3.x (Dart SDK ^3.11.0)
- Git

### Backend Setup

```bash
# 1. Navigate to backend directory
cd backend

# 2. Create and activate virtual environment
python -m venv venv
source venv/bin/activate    # macOS/Linux
# venv\Scripts\activate     # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up environment variables
cp .env.example .env
# Edit .env with your API keys (optional - runs in demo mode without them)

# 5. Run the server
python run.py
# Server starts on http://localhost:8000
```

The backend will run in **demo mode** (in-memory storage) if `FIREBASE_CREDENTIALS_PATH` and `GEMINI_API_KEY` are not set. This is perfectly fine for development.

### Flutter Setup

```bash
# 1. Navigate to Flutter project
cd bharat_brief

# 2. Install dependencies
flutter pub get

# 3. Run on Chrome (web)
flutter run -d chrome

# 4. Run on macOS (desktop)
flutter run -d macos

# 5. Run on connected Android device
flutter run -d <device_id>
```

### Building Android APK

```bash
# 1. Set environment variables (macOS with Homebrew)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
# Or if installed via Homebrew:
# export JAVA_HOME="/opt/homebrew/opt/openjdk@17"

# 2. Build debug APK
cd bharat_brief
flutter build apk --debug

# 3. APK output location
# bharat_brief/build/app/outputs/flutter-apk/app-debug.apk
```

### Environment Variables Explained

| Variable | Purpose |
|---|---|
| `GEMINI_API_KEY` | Google AI Studio API key. Get one at [https://aistudio.google.com/](https://aistudio.google.com/). Enables AI summaries and quiz generation. |
| `FIREBASE_CREDENTIALS_PATH` | Path to Firebase service account JSON file. Download from Firebase Console > Project Settings > Service Accounts. Enables Firestore persistence. |
| `BHASHINI_USER_ID` | Register at [https://bhashini.gov.in/ulca](https://bhashini.gov.in/ulca) to get credentials. Enables translation to 13 languages. |
| `BHASHINI_API_KEY` | ULCA API key for Bhashini pipeline access. |
| `BHASHINI_AUTH_TOKEN` | Auth token for Bhashini compute endpoints (TTS, translation). |

### API Testing

Once the backend is running locally:

```bash
# Health check
curl http://localhost:8000/api/health

# Fetch articles
curl "http://localhost:8000/api/articles?lang=en&category=national&limit=5"

# Trigger RSS fetch
curl -X POST http://localhost:8000/api/trigger-fetch

# Get stats
curl http://localhost:8000/api/stats

# Get supported languages
curl http://localhost:8000/api/languages
```

---

## Project Structure

```
BharatBrief/
├── backend/
│   ├── app.py                    # Flask app factory, all route definitions
│   ├── run.py                    # Entry point (starts Flask server)
│   ├── Procfile                  # Railway deployment config
│   ├── requirements.txt          # Python dependencies
│   ├── config/
│   │   ├── settings.py           # Environment variable loading
│   │   ├── rss_feeds.py          # 43+ RSS feed definitions
│   │   └── languages.py          # 13 supported languages
│   ├── services/
│   │   ├── firebase_service.py   # Firestore + in-memory storage
│   │   ├── rss_service.py        # RSS fetch, parse, deduplicate
│   │   ├── gemini_service.py     # Gemini AI summarization
│   │   ├── bhashini_service.py   # Bhashini translation + TTS
│   │   ├── scheduler_service.py  # APScheduler background jobs
│   │   └── notification_service.py # FCM push notifications
│   └── utils/
│       └── helpers.py            # Utility functions (clean_html, truncate, etc.)
│
├── bharat_brief/                 # Flutter app
│   ├── pubspec.yaml              # Flutter dependencies
│   ├── lib/
│   │   ├── main.dart             # App entry point, Provider setup
│   │   ├── config/
│   │   │   ├── constants.dart    # API URLs, AdMob IDs, language/category lists
│   │   │   └── theme.dart        # Light/dark theme definitions
│   │   ├── models/
│   │   │   ├── article.dart      # Article + Summary data models
│   │   │   ├── quiz.dart         # Quiz data model
│   │   │   └── user.dart         # User data model
│   │   ├── providers/
│   │   │   ├── article_provider.dart
│   │   │   ├── quiz_provider.dart
│   │   │   ├── settings_provider.dart
│   │   │   └── user_provider.dart
│   │   ├── services/
│   │   │   ├── api_service.dart   # HTTP client for backend API
│   │   │   ├── audio_service.dart # TTS audio playback
│   │   │   └── storage_service.dart # Local persistence
│   │   └── screens/
│   │       ├── home/              # Home screen with swipeable cards
│   │       └── onboarding/        # Language, state, category selection
│   └── assets/
│       ├── images/
│       └── icons/
│
└── documentation.md              # This file
```
