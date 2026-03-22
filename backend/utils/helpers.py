"""
Utility functions for BharatBrief backend.
"""

import re
import logging
from datetime import datetime, timezone

from config.rss_feeds import SOURCE_STATE_MAP

logger = logging.getLogger(__name__)


def truncate_text(text, word_count=60):
    """Truncate text to a given number of words."""
    if not text:
        return ""
    words = text.split()
    if len(words) <= word_count:
        return text
    return " ".join(words[:word_count]) + "..."


def calculate_similarity(text1, text2):
    """
    Calculate simple word-overlap similarity ratio between two texts.
    Returns a float between 0.0 and 1.0.
    """
    if not text1 or not text2:
        return 0.0

    words1 = set(text1.lower().split())
    words2 = set(text2.lower().split())

    if not words1 or not words2:
        return 0.0

    intersection = words1 & words2
    union = words1 | words2

    return len(intersection) / len(union) if union else 0.0


def clean_html(html_text):
    """Strip HTML tags from text."""
    if not html_text:
        return ""
    clean = re.sub(r"<[^>]+>", "", html_text)
    # Collapse whitespace
    clean = re.sub(r"\s+", " ", clean).strip()
    return clean


def format_time_ago(timestamp):
    """
    Format a datetime or ISO string as a human-readable relative time.
    Returns strings like '2h ago', '5m ago', '1d ago'.
    """
    if not timestamp:
        return ""

    if isinstance(timestamp, str):
        try:
            timestamp = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        except (ValueError, TypeError):
            return ""

    now = datetime.now(timezone.utc)
    if timestamp.tzinfo is None:
        timestamp = timestamp.replace(tzinfo=timezone.utc)

    diff = now - timestamp
    total_seconds = int(diff.total_seconds())

    if total_seconds < 0:
        return "just now"
    elif total_seconds < 60:
        return f"{total_seconds}s ago"
    elif total_seconds < 3600:
        minutes = total_seconds // 60
        return f"{minutes}m ago"
    elif total_seconds < 86400:
        hours = total_seconds // 3600
        return f"{hours}h ago"
    else:
        days = total_seconds // 86400
        return f"{days}d ago"


def extract_state_from_source(source_name):
    """Map a regional news source name to an Indian state code."""
    if not source_name:
        return None
    return SOURCE_STATE_MAP.get(source_name)
