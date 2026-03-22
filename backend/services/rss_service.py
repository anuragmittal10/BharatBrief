"""
RSS feed fetcher and parser for BharatBrief.
"""

import hashlib
import logging
import time
from datetime import datetime, timezone, timedelta

import feedparser

from config.rss_feeds import RSS_FEEDS
from utils.helpers import clean_html, calculate_similarity, truncate_text

logger = logging.getLogger(__name__)


def generate_article_id(title, link):
    """Generate a deterministic MD5 hash ID from title + link."""
    raw = (title or "").strip().lower() + (link or "").strip()
    return hashlib.md5(raw.encode("utf-8")).hexdigest()


def _extract_image(entry):
    """Try to extract an image URL from various RSS entry fields."""
    # media:content
    media_content = entry.get("media_content", [])
    if media_content:
        for media in media_content:
            url = media.get("url", "")
            if url and ("image" in media.get("type", "") or media.get("medium") == "image"):
                return url
        # If type not specified, take the first one
        if media_content[0].get("url"):
            return media_content[0]["url"]

    # media:thumbnail
    media_thumbnail = entry.get("media_thumbnail", [])
    if media_thumbnail and media_thumbnail[0].get("url"):
        return media_thumbnail[0]["url"]

    # enclosures
    enclosures = entry.get("enclosures", [])
    for enc in enclosures:
        if "image" in enc.get("type", ""):
            return enc.get("href") or enc.get("url", "")

    # links with image type
    for link in entry.get("links", []):
        if "image" in link.get("type", ""):
            return link.get("href", "")

    return None


def _parse_published_date(entry):
    """Parse the published date from a feed entry."""
    published_parsed = entry.get("published_parsed") or entry.get("updated_parsed")
    if published_parsed:
        try:
            dt = datetime(*published_parsed[:6], tzinfo=timezone.utc)
            return dt
        except (TypeError, ValueError):
            pass

    date_str = entry.get("published") or entry.get("updated")
    if date_str:
        try:
            return datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        except (ValueError, TypeError):
            pass

    return datetime.now(timezone.utc)


def parse_feed_entry(entry, feed_config):
    """Parse a single feed entry into a normalized article dict."""
    title = entry.get("title", "").strip()
    link = entry.get("link", "").strip()

    if not title or not link:
        return None

    description = clean_html(
        entry.get("summary", "") or entry.get("description", "")
    )

    article = {
        "id": generate_article_id(title, link),
        "title": title,
        "link": link,
        "description": description,
        "image_url": _extract_image(entry),
        "published_at": _parse_published_date(entry),
        "source": feed_config["source"],
        "category": feed_config["category"],
        "language": feed_config["language"],
        "state": feed_config.get("state"),
        # These will be filled by Gemini
        "headline": None,
        "summary": None,
        "mood_tag": None,
        "translations": {},
        "tts_urls": {},
    }
    return article


def fetch_single_feed(feed_config):
    """Fetch and parse a single RSS feed. Returns list of article dicts."""
    url = feed_config["url"]
    articles = []
    try:
        feed = feedparser.parse(url)
        if feed.bozo and not feed.entries:
            logger.warning("Feed error for %s (%s): %s", feed_config["source"], url, feed.bozo_exception)
            return []

        for entry in feed.entries:
            article = parse_feed_entry(entry, feed_config)
            if article:
                articles.append(article)

        logger.info("Fetched %d articles from %s", len(articles), feed_config["source"])
    except Exception as e:
        logger.error("Error fetching feed %s: %s", feed_config["source"], e)

    return articles


def fetch_all_feeds():
    """Fetch all configured RSS feeds and return combined article list."""
    all_articles = []
    for feed_config in RSS_FEEDS:
        articles = fetch_single_feed(feed_config)
        all_articles.extend(articles)
        # Small delay to be polite to servers
        time.sleep(0.1)

    logger.info("Total articles fetched from all feeds: %d", len(all_articles))
    return all_articles


def deduplicate(articles):
    """
    Remove duplicate articles by:
    1. Exact hash match
    2. 80%+ title similarity
    """
    seen_ids = set()
    seen_titles = []
    unique = []

    for article in articles:
        aid = article["id"]
        title = article.get("title", "")

        # Skip exact duplicates
        if aid in seen_ids:
            continue

        # Skip near-duplicate titles
        is_similar = False
        for existing_title in seen_titles:
            if calculate_similarity(title, existing_title) >= 0.8:
                is_similar = True
                break

        if is_similar:
            continue

        seen_ids.add(aid)
        seen_titles.append(title)
        unique.append(article)

    removed = len(articles) - len(unique)
    if removed > 0:
        logger.info("Deduplication removed %d articles, %d remain", removed, len(unique))

    return unique


def filter_old_articles(articles, max_age_hours=48):
    """Remove articles older than max_age_hours."""
    cutoff = datetime.now(timezone.utc) - timedelta(hours=max_age_hours)
    filtered = []
    for article in articles:
        pub = article.get("published_at")
        if pub and pub.tzinfo is None:
            pub = pub.replace(tzinfo=timezone.utc)
        if pub and pub >= cutoff:
            filtered.append(article)
        elif not pub:
            # Keep articles without a publish date (assume recent)
            filtered.append(article)

    removed = len(articles) - len(filtered)
    if removed > 0:
        logger.info("Filtered out %d old articles (>%dh)", removed, max_age_hours)

    return filtered
