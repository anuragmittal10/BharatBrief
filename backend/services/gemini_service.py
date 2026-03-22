"""
Gemini API service for article summarization, quiz generation, and deep summaries.
"""

import json
import logging
import time

from utils.helpers import truncate_text

genai = None  # lazy loaded

logger = logging.getLogger(__name__)

_model = None


def init_gemini(api_key):
    """Initialize the Gemini generative model."""
    global _model, genai
    try:
        import google.generativeai as _genai
        genai = _genai
        genai.configure(api_key=api_key)
        _model = genai.GenerativeModel("gemini-1.5-flash")
        logger.info("Gemini model initialized successfully.")
        return True
    except Exception as e:
        logger.error("Failed to initialize Gemini: %s", e)
        return False


def _get_model():
    if _model is None:
        raise RuntimeError("Gemini not initialized. Call init_gemini() first.")
    return _model


def summarize_article(title, description):
    """
    Summarize a single article using Gemini.
    Returns dict with headline, summary, category, and mood_tag.
    Falls back to truncated description on failure.
    """
    model = _get_model()

    prompt = f"""You are a news summarizer for an Indian news app. Given the article title and description, produce a JSON object with exactly these keys:
- "headline": a crisp headline of at most 10 words
- "summary": a neutral summary of at most 60 words
- "category": one of [national, world, business, sports, tech, entertainment, science, health]
- "mood_tag": one of [positive, negative, neutral]

Article Title: {title}
Article Description: {description}

Respond ONLY with valid JSON, no markdown or extra text."""

    try:
        response = model.generate_content(prompt)
        text = response.text.strip()
        # Strip markdown code fences if present
        if text.startswith("```"):
            text = text.split("\n", 1)[1] if "\n" in text else text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        result = json.loads(text)
        # Validate keys
        for key in ("headline", "summary", "category", "mood_tag"):
            if key not in result:
                raise ValueError(f"Missing key: {key}")
        return result
    except Exception as e:
        logger.warning("Gemini summarization failed for '%s': %s. Using fallback.", title[:50], e)
        return {
            "headline": truncate_text(title, 10),
            "summary": truncate_text(description, 60),
            "category": "national",
            "mood_tag": "neutral",
        }


def summarize_batch(articles, batch_size=50, batch_delay=2):
    """
    Process articles in batches through Gemini.
    Modifies articles in place with headline, summary, category, mood_tag.
    Returns the list of processed articles.
    """
    total = len(articles)
    logger.info("Starting Gemini batch summarization for %d articles", total)

    for i in range(0, total, batch_size):
        batch = articles[i : i + batch_size]
        for article in batch:
            title = article.get("title", "")
            description = article.get("description", "")
            result = summarize_article(title, description)
            article["headline"] = result["headline"]
            article["summary"] = result["summary"]
            article["category"] = result["category"]
            article["mood_tag"] = result["mood_tag"]

        processed = min(i + batch_size, total)
        logger.info("Summarized %d / %d articles", processed, total)

        # Delay between batches to respect rate limits
        if processed < total:
            time.sleep(batch_delay)

    return articles


def generate_quiz_questions(articles):
    """
    Generate 5 MCQ questions from the top articles of the day.
    Returns list of question dicts.
    """
    model = _get_model()

    # Build context from top articles
    context_parts = []
    for idx, article in enumerate(articles[:20], 1):
        headline = article.get("headline") or article.get("title", "")
        summary = article.get("summary") or article.get("description", "")
        context_parts.append(f"{idx}. {headline}: {summary}")

    context = "\n".join(context_parts)

    prompt = f"""Based on the following news articles from today, generate exactly 5 multiple-choice quiz questions to test a reader's knowledge of current events.

News Articles:
{context}

Return a JSON array of 5 objects, each with:
- "question": the question text
- "options": array of exactly 4 option strings
- "correct_index": integer 0-3 indicating the correct answer
- "explanation": one sentence explaining the answer

Respond ONLY with valid JSON array, no markdown or extra text."""

    try:
        response = model.generate_content(prompt)
        text = response.text.strip()
        if text.startswith("```"):
            text = text.split("\n", 1)[1] if "\n" in text else text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        questions = json.loads(text)
        if isinstance(questions, list) and len(questions) >= 1:
            return questions[:5]
        raise ValueError("Invalid quiz response format")
    except Exception as e:
        logger.error("Failed to generate quiz questions: %s", e)
        return []


def generate_deep_summary(title, description):
    """
    Generate an extended 200-word summary for Deep Mode.
    """
    model = _get_model()

    prompt = f"""You are a news analyst for an Indian news app. Given the article title and description, write an in-depth summary of approximately 200 words that provides context, background, and implications.

Article Title: {title}
Article Description: {description}

Write in clear, objective journalistic prose. Do not use markdown formatting."""

    try:
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        logger.warning("Deep summary failed for '%s': %s", title[:50], e)
        return truncate_text(description, 200)
