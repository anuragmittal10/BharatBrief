"""
Bhashini (ULCA) API integration for translation and TTS.
"""

import io
import logging
import uuid

import requests

from config.settings import CONFIG

logger = logging.getLogger(__name__)

# Cache pipeline configs to avoid repeated lookups
_pipeline_cache = {}

BHASHINI_PIPELINE_URL = "https://meity-auth.ulcacontrib.org/ulca/apis/v0/model/getModelsPipeline"


def _get_headers():
    """Build auth headers for Bhashini API."""
    return {
        "Content-Type": "application/json",
        "userID": CONFIG.get("BHASHINI_USER_ID", ""),
        "ulcaApiKey": CONFIG.get("BHASHINI_API_KEY", ""),
    }


def _get_compute_headers():
    """Build auth headers for Bhashini compute endpoint."""
    return {
        "Content-Type": "application/json",
        "Authorization": CONFIG.get("BHASHINI_AUTH_TOKEN", ""),
    }


def get_translation_config(source_lang, target_lang):
    """
    Call the Bhashini pipeline search API to get the NMT model config.
    Caches results for repeated language pairs.
    """
    cache_key = f"nmt_{source_lang}_{target_lang}"
    if cache_key in _pipeline_cache:
        return _pipeline_cache[cache_key]

    payload = {
        "pipelineTasks": [
            {
                "taskType": "translation",
                "config": {
                    "language": {
                        "sourceLanguage": source_lang,
                        "targetLanguage": target_lang,
                    }
                },
            }
        ],
        "pipelineRequestConfig": {
            "pipelineId": "64392f96daac500b55c543cd",
        },
    }

    try:
        resp = requests.post(BHASHINI_PIPELINE_URL, json=payload, headers=_get_headers(), timeout=30)
        resp.raise_for_status()
        data = resp.json()

        pipeline_config = data.get("pipelineResponseConfig", [{}])[0]
        service_url = data.get("pipelineInferenceAPIEndPoint", {}).get("callbackUrl", "")
        inference_key = (
            data.get("pipelineInferenceAPIEndPoint", {})
            .get("inferenceApiKey", {})
            .get("value", "")
        )

        config = pipeline_config.get("config", [{}])[0]

        result = {
            "service_url": service_url,
            "inference_key": inference_key,
            "service_id": config.get("serviceId", ""),
            "model_id": config.get("modelId", ""),
        }
        _pipeline_cache[cache_key] = result
        logger.debug("Cached translation config for %s -> %s", source_lang, target_lang)
        return result
    except Exception as e:
        logger.error("Failed to get translation config for %s -> %s: %s", source_lang, target_lang, e)
        return None


def get_tts_config(language):
    """
    Call the Bhashini pipeline search API to get TTS model config.
    """
    cache_key = f"tts_{language}"
    if cache_key in _pipeline_cache:
        return _pipeline_cache[cache_key]

    payload = {
        "pipelineTasks": [
            {
                "taskType": "tts",
                "config": {
                    "language": {
                        "sourceLanguage": language,
                    }
                },
            }
        ],
        "pipelineRequestConfig": {
            "pipelineId": "64392f96daac500b55c543cd",
        },
    }

    try:
        resp = requests.post(BHASHINI_PIPELINE_URL, json=payload, headers=_get_headers(), timeout=30)
        resp.raise_for_status()
        data = resp.json()

        pipeline_config = data.get("pipelineResponseConfig", [{}])[0]
        service_url = data.get("pipelineInferenceAPIEndPoint", {}).get("callbackUrl", "")
        inference_key = (
            data.get("pipelineInferenceAPIEndPoint", {})
            .get("inferenceApiKey", {})
            .get("value", "")
        )

        config = pipeline_config.get("config", [{}])[0]

        result = {
            "service_url": service_url,
            "inference_key": inference_key,
            "service_id": config.get("serviceId", ""),
            "model_id": config.get("modelId", ""),
        }
        _pipeline_cache[cache_key] = result
        logger.debug("Cached TTS config for %s", language)
        return result
    except Exception as e:
        logger.error("Failed to get TTS config for %s: %s", language, e)
        return None


def translate_text(text, source_lang, target_lang):
    """
    Translate text from source_lang to target_lang using Bhashini NMT.
    Returns translated text or None on failure.
    """
    if source_lang == target_lang:
        return text

    config = get_translation_config(source_lang, target_lang)
    if not config:
        logger.error("No translation config available for %s -> %s", source_lang, target_lang)
        return None

    payload = {
        "pipelineTasks": [
            {
                "taskType": "translation",
                "config": {
                    "language": {
                        "sourceLanguage": source_lang,
                        "targetLanguage": target_lang,
                    },
                    "serviceId": config["service_id"],
                },
            }
        ],
        "inputData": {
            "input": [{"source": text}],
        },
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": config.get("inference_key") or CONFIG.get("BHASHINI_AUTH_TOKEN", ""),
    }

    try:
        resp = requests.post(config["service_url"], json=payload, headers=headers, timeout=60)
        resp.raise_for_status()
        data = resp.json()
        output = data.get("pipelineResponse", [{}])[0].get("output", [{}])
        if output:
            return output[0].get("target", "")
        return None
    except Exception as e:
        logger.error("Translation failed for %s -> %s: %s", source_lang, target_lang, e)
        return None


def translate_article_to_all_languages(article_summary, source_lang="en"):
    """
    Translate an article summary (headline + summary) to all supported languages.
    Returns dict mapping language code to {"headline": ..., "summary": ...}.
    """
    from config.languages import SUPPORTED_LANGUAGES

    translations = {}
    headline = article_summary.get("headline", "")
    summary = article_summary.get("summary", "")

    for lang in SUPPORTED_LANGUAGES:
        target_lang = lang["code"]
        if target_lang == source_lang:
            translations[target_lang] = {"headline": headline, "summary": summary}
            continue

        try:
            translated_headline = translate_text(headline, source_lang, target_lang)
            translated_summary = translate_text(summary, source_lang, target_lang)

            if translated_headline and translated_summary:
                translations[target_lang] = {
                    "headline": translated_headline,
                    "summary": translated_summary,
                }
                logger.debug("Translated to %s successfully", target_lang)
            else:
                logger.warning("Partial or no translation for %s", target_lang)
        except Exception as e:
            logger.error("Translation to %s failed: %s", target_lang, e)

    return translations


def generate_tts(text, language):
    """
    Generate TTS audio via Bhashini TTS API.
    Returns audio bytes (WAV format) or None on failure.
    """
    config = get_tts_config(language)
    if not config:
        logger.error("No TTS config available for %s", language)
        return None

    payload = {
        "pipelineTasks": [
            {
                "taskType": "tts",
                "config": {
                    "language": {
                        "sourceLanguage": language,
                    },
                    "serviceId": config["service_id"],
                    "gender": "female",
                    "samplingRate": 8000,
                },
            }
        ],
        "inputData": {
            "input": [{"source": text}],
        },
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": config.get("inference_key") or CONFIG.get("BHASHINI_AUTH_TOKEN", ""),
    }

    try:
        resp = requests.post(config["service_url"], json=payload, headers=headers, timeout=120)
        resp.raise_for_status()
        data = resp.json()

        audio_content = (
            data.get("pipelineResponse", [{}])[0]
            .get("audio", [{}])[0]
            .get("audioContent", "")
        )
        if audio_content:
            import base64
            return base64.b64decode(audio_content)
        return None
    except Exception as e:
        logger.error("TTS generation failed for %s: %s", language, e)
        return None


def save_tts_audio(article_id, language, audio_bytes):
    """
    Save TTS audio bytes to Firebase Storage and return the public URL.
    """
    try:
        from firebase_admin import storage
        bucket = storage.bucket()
        blob_path = f"tts/{article_id}/{language}.wav"
        blob = bucket.blob(blob_path)
        blob.upload_from_string(audio_bytes, content_type="audio/wav")
        blob.make_public()
        url = blob.public_url
        logger.info("Saved TTS audio: %s", blob_path)
        return url
    except Exception as e:
        logger.error("Failed to save TTS audio for %s/%s: %s", article_id, language, e)
        return None
