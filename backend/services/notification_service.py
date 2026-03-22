"""
Firebase Cloud Messaging (FCM) notification service for BharatBrief.
"""

import logging

logger = logging.getLogger(__name__)


def _get_messaging():
    from firebase_admin import messaging
    return messaging


def _send_to_topic(topic, title, body, data=None):
    """Send a notification to an FCM topic."""
    try:
        messaging = _get_messaging()
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            topic=topic,
        )
        response = messaging.send(message)
        logger.info("Notification sent to topic '%s': %s", topic, response)
        return response
    except Exception as e:
        logger.error("Failed to send notification to topic '%s': %s", topic, e)
        return None


def send_morning_digest(language="en"):
    """
    Send morning digest notification (top 10 stories) at 8 AM.
    """
    from services.firebase_service import get_trending_articles

    try:
        articles = get_trending_articles(language=language, limit=10)
        if not articles:
            logger.info("No articles for morning digest in %s", language)
            return

        headlines = []
        for a in articles[:5]:
            headline = a.get("headline") or a.get("title", "")
            if headline:
                headlines.append(headline)

        body = " | ".join(headlines) if headlines else "Check out today's top stories!"

        topic = f"digest_{language}"
        _send_to_topic(
            topic=topic,
            title="Good Morning! Your Daily Brief",
            body=body,
            data={"type": "morning_digest", "language": language},
        )
    except Exception as e:
        logger.error("Error sending morning digest: %s", e)


def send_evening_digest(language="en"):
    """
    Send evening digest + quiz prompt at 8 PM.
    """
    from services.firebase_service import get_today_quiz

    try:
        quiz = get_today_quiz()
        quiz_available = "yes" if quiz else "no"

        topic = f"digest_{language}"
        _send_to_topic(
            topic=topic,
            title="Evening Recap & Daily Quiz",
            body="Here's your day in review. Ready for today's news quiz?",
            data={
                "type": "evening_digest",
                "language": language,
                "quiz_available": quiz_available,
            },
        )
    except Exception as e:
        logger.error("Error sending evening digest: %s", e)


def send_breaking_news(article):
    """
    Send a real-time push notification for a breaking/trending article.
    """
    try:
        headline = article.get("headline") or article.get("title", "Breaking News")
        summary = article.get("summary") or article.get("description", "")
        language = article.get("language", "en")

        topic = f"breaking_{language}"
        _send_to_topic(
            topic=topic,
            title=headline,
            body=summary[:200],
            data={
                "type": "breaking_news",
                "article_id": article.get("id", ""),
                "language": language,
            },
        )
    except Exception as e:
        logger.error("Error sending breaking news notification: %s", e)


def send_quiz_reminder():
    """Send quiz-ready notification at 8 PM."""
    try:
        _send_to_topic(
            topic="quiz",
            title="Daily News Quiz is Ready!",
            body="Test your knowledge of today's top stories. 5 questions await!",
            data={"type": "quiz_reminder"},
        )
    except Exception as e:
        logger.error("Error sending quiz reminder: %s", e)


def subscribe_to_topic(token, topic):
    """Subscribe a device token to an FCM topic."""
    try:
        messaging = _get_messaging()
        response = messaging.subscribe_to_topic([token], topic)
        logger.info("Subscribed to topic '%s': %d success", topic, response.success_count)
        return response.success_count > 0
    except Exception as e:
        logger.error("Error subscribing to topic '%s': %s", topic, e)
        return False


def unsubscribe_from_topic(token, topic):
    """Unsubscribe a device token from an FCM topic."""
    try:
        messaging = _get_messaging()
        response = messaging.unsubscribe_from_topic([token], topic)
        logger.info("Unsubscribed from topic '%s': %d success", topic, response.success_count)
        return response.success_count > 0
    except Exception as e:
        logger.error("Error unsubscribing from topic '%s': %s", topic, e)
        return False
