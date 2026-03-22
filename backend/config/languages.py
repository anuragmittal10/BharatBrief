"""
Supported languages configuration for BharatBrief.
"""

SUPPORTED_LANGUAGES = [
    {"code": "en", "name": "English", "native_name": "English", "script": "Latin"},
    {"code": "hi", "name": "Hindi", "native_name": "\u0939\u093f\u0928\u094d\u0926\u0940", "script": "Devanagari"},
    {"code": "ta", "name": "Tamil", "native_name": "\u0ba4\u0bae\u0bbf\u0bb4\u0bcd", "script": "Tamil"},
    {"code": "te", "name": "Telugu", "native_name": "\u0c24\u0c46\u0c32\u0c41\u0c17\u0c41", "script": "Telugu"},
    {"code": "mr", "name": "Marathi", "native_name": "\u092e\u0930\u093e\u0920\u0940", "script": "Devanagari"},
    {"code": "bn", "name": "Bengali", "native_name": "\u09ac\u09be\u0982\u09b2\u09be", "script": "Bengali"},
    {"code": "kn", "name": "Kannada", "native_name": "\u0c95\u0ca8\u0ccd\u0ca8\u0ca1", "script": "Kannada"},
    {"code": "ml", "name": "Malayalam", "native_name": "\u0d2e\u0d32\u0d2f\u0d3e\u0d33\u0d02", "script": "Malayalam"},
    {"code": "gu", "name": "Gujarati", "native_name": "\u0a97\u0ac1\u0a9c\u0ab0\u0abe\u0aa4\u0ac0", "script": "Gujarati"},
    {"code": "pa", "name": "Punjabi", "native_name": "\u0a2a\u0a70\u0a1c\u0a3e\u0a2c\u0a40", "script": "Gurmukhi"},
    {"code": "or", "name": "Odia", "native_name": "\u0b13\u0b21\u0b3c\u0b3f\u0b06", "script": "Odia"},
    {"code": "as", "name": "Assamese", "native_name": "\u0985\u09b8\u09ae\u09c0\u09af\u09bc\u09be", "script": "Assamese"},
    {"code": "ur", "name": "Urdu", "native_name": "\u0627\u0631\u062f\u0648", "script": "Nastaliq"},
]

# Quick lookup maps
LANGUAGE_CODE_MAP = {lang["code"]: lang for lang in SUPPORTED_LANGUAGES}
LANGUAGE_NAMES = {lang["code"]: lang["name"] for lang in SUPPORTED_LANGUAGES}
