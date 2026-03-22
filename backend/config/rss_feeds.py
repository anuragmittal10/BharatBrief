"""
RSS feed configuration for BharatBrief.
40+ feeds organized by category covering national, international, and regional news.
"""

RSS_FEEDS = [
    # ===================== NATIONAL =====================
    {"url": "https://feeds.feedburner.com/ndtvnews-top-stories", "source": "NDTV", "category": "national", "language": "en", "state": None},
    {"url": "https://timesofindia.indiatimes.com/rssfeedstopstories.cms", "source": "Times of India", "category": "national", "language": "en", "state": None},
    {"url": "https://www.thehindu.com/news/national/feeder/default.rss", "source": "The Hindu", "category": "national", "language": "en", "state": None},
    {"url": "https://indianexpress.com/section/india/feed/", "source": "Indian Express", "category": "national", "language": "en", "state": None},
    {"url": "https://www.hindustantimes.com/feeds/rss/india-news/rssfeed.xml", "source": "Hindustan Times", "category": "national", "language": "en", "state": None},
    {"url": "https://www.news18.com/rss/india.xml", "source": "News18", "category": "national", "language": "en", "state": None},
    {"url": "https://www.amarujala.com/rss/breaking-news.xml", "source": "Amar Ujala", "category": "national", "language": "hi", "state": None},
    {"url": "https://navbharattimes.indiatimes.com/rssfeedsdefault.cms", "source": "Navbharat Times", "category": "national", "language": "hi", "state": None},
    {"url": "https://www.jagran.com/rss/national-news.xml", "source": "Dainik Jagran", "category": "national", "language": "hi", "state": None},
    {"url": "https://www.livehindustan.com/rss/nation", "source": "Live Hindustan", "category": "national", "language": "hi", "state": None},

    # ===================== WORLD =====================
    {"url": "https://feeds.reuters.com/reuters/INtopNews", "source": "Reuters", "category": "world", "language": "en", "state": None},
    {"url": "https://feeds.bbci.co.uk/news/world/rss.xml", "source": "BBC World", "category": "world", "language": "en", "state": None},
    {"url": "https://feeds.feedburner.com/ndtvnews-world-news", "source": "NDTV World", "category": "world", "language": "en", "state": None},
    {"url": "https://www.news18.com/rss/world.xml", "source": "News18 World", "category": "world", "language": "en", "state": None},
    {"url": "https://www.bbc.com/hindi/index.xml", "source": "BBC Hindi", "category": "world", "language": "hi", "state": None},
    {"url": "https://www.hindustantimes.com/feeds/rss/world-news/rssfeed.xml", "source": "HT World", "category": "world", "language": "en", "state": None},

    # ===================== BUSINESS =====================
    {"url": "https://www.business-standard.com/rss/home_page_top_stories.rss", "source": "Business Standard", "category": "business", "language": "en", "state": None},
    {"url": "https://economictimes.indiatimes.com/rssfeedstopstories.cms", "source": "Economic Times", "category": "business", "language": "en", "state": None},
    {"url": "https://www.moneycontrol.com/rss/latestnews.xml", "source": "Moneycontrol", "category": "business", "language": "en", "state": None},
    {"url": "https://www.livemint.com/rss/markets", "source": "Livemint", "category": "business", "language": "en", "state": None},
    {"url": "https://feeds.feedburner.com/ndtvprofit-latest", "source": "NDTV Profit", "category": "business", "language": "en", "state": None},

    # ===================== SPORTS =====================
    {"url": "https://www.espncricinfo.com/rss/content/story/feeds/0.xml", "source": "ESPN Cricinfo", "category": "sports", "language": "en", "state": None},
    {"url": "https://www.cricbuzz.com/cb-rss-feeds", "source": "Cricbuzz", "category": "sports", "language": "en", "state": None},
    {"url": "https://feeds.feedburner.com/ndtvsports-latest", "source": "NDTV Sports", "category": "sports", "language": "en", "state": None},
    {"url": "https://timesofindia.indiatimes.com/rssfeeds/4719148.cms", "source": "TOI Sports", "category": "sports", "language": "en", "state": None},
    {"url": "https://www.news18.com/rss/cricketnext.xml", "source": "News18 Sports", "category": "sports", "language": "en", "state": None},

    # ===================== TECH =====================
    {"url": "https://feeds.feedburner.com/gadgets360-latest", "source": "Gadgets360", "category": "tech", "language": "en", "state": None},
    {"url": "https://www.firstpost.com/rss/tech.xml", "source": "Firstpost Tech", "category": "tech", "language": "en", "state": None},
    {"url": "https://indianexpress.com/section/technology/feed/", "source": "IE Tech", "category": "tech", "language": "en", "state": None},
    {"url": "https://timesofindia.indiatimes.com/rssfeeds/66949542.cms", "source": "TOI Tech", "category": "tech", "language": "en", "state": None},

    # ===================== ENTERTAINMENT =====================
    {"url": "https://www.bollywoodhungama.com/rss/news.xml", "source": "Bollywood Hungama", "category": "entertainment", "language": "en", "state": None},
    {"url": "https://www.filmfare.com/rss.xml", "source": "Filmfare", "category": "entertainment", "language": "en", "state": None},
    {"url": "https://timesofindia.indiatimes.com/rssfeeds/1081479906.cms", "source": "TOI Entertainment", "category": "entertainment", "language": "en", "state": None},
    {"url": "https://www.news18.com/rss/entertainment.xml", "source": "News18 Entertainment", "category": "entertainment", "language": "en", "state": None},

    # ===================== STATE / REGIONAL =====================
    # Tamil Nadu
    {"url": "https://www.dinamalar.com/rss_feed.asp", "source": "Dinamalar", "category": "national", "language": "ta", "state": "TN"},
    {"url": "https://www.dailythanthi.com/rssfeeds/rss_tamilnadu.xml", "source": "Daily Thanthi", "category": "national", "language": "ta", "state": "TN"},

    # Telugu (Andhra Pradesh / Telangana)
    {"url": "https://www.eenadu.net/rss/mainnews-rss.xml", "source": "Eenadu", "category": "national", "language": "te", "state": "AP"},
    {"url": "https://www.sakshi.com/rss.xml", "source": "Sakshi", "category": "national", "language": "te", "state": "TS"},

    # Kannada (Karnataka)
    {"url": "https://www.prajavani.net/rss_feed", "source": "Prajavani", "category": "national", "language": "kn", "state": "KA"},

    # Malayalam (Kerala)
    {"url": "https://www.mathrubhumi.com/rss/news", "source": "Mathrubhumi", "category": "national", "language": "ml", "state": "KL"},
    {"url": "https://www.manoramaonline.com/news.rss.xml", "source": "Manorama Online", "category": "national", "language": "ml", "state": "KL"},

    # Marathi (Maharashtra)
    {"url": "https://www.loksatta.com/feed/", "source": "Loksatta", "category": "national", "language": "mr", "state": "MH"},

    # Bengali (West Bengal)
    {"url": "https://www.anandabazar.com/rss/all-news", "source": "Anandabazar Patrika", "category": "national", "language": "bn", "state": "WB"},

    # Gujarati (Gujarat)
    {"url": "https://www.divyabhaskar.co.in/rss/gujfeed.xml", "source": "Divya Bhaskar", "category": "national", "language": "gu", "state": "GJ"},

    # Punjabi (Punjab)
    {"url": "https://www.ajitjalandhar.com/rss/rssfeed.xml", "source": "Ajit", "category": "national", "language": "pa", "state": "PB"},

    # Uttar Pradesh
    {"url": "https://www.amarujala.com/rss/uttar-pradesh.xml", "source": "Amar Ujala UP", "category": "national", "language": "hi", "state": "UP"},
    {"url": "https://www.jagran.com/rss/uttar-pradesh-news.xml", "source": "Dainik Jagran UP", "category": "national", "language": "hi", "state": "UP"},

    # Delhi
    {"url": "https://www.livehindustan.com/rss/delhi", "source": "Live Hindustan Delhi", "category": "national", "language": "hi", "state": "DL"},
    {"url": "https://www.amarujala.com/rss/delhi-ncr.xml", "source": "Amar Ujala Delhi", "category": "national", "language": "hi", "state": "DL"},

    # Bihar
    {"url": "https://www.jagran.com/rss/bihar-news.xml", "source": "Dainik Jagran Bihar", "category": "national", "language": "hi", "state": "BR"},

    # Rajasthan
    {"url": "https://www.jagran.com/rss/rajasthan-news.xml", "source": "Dainik Jagran Rajasthan", "category": "national", "language": "hi", "state": "RJ"},

    # ===================== SCIENCE =====================
    {"url": "https://www.sciencedaily.com/rss/all.xml", "source": "ScienceDaily", "category": "science", "language": "en", "state": None},
    {"url": "https://timesofindia.indiatimes.com/rssfeeds/39905737.cms", "source": "TOI Science", "category": "science", "language": "en", "state": None},
    {"url": "https://indianexpress.com/section/technology/science/feed/", "source": "IE Science", "category": "science", "language": "en", "state": None},

    # ===================== HEALTH =====================
    {"url": "https://timesofindia.indiatimes.com/rssfeeds/3908999.cms", "source": "TOI Health", "category": "health", "language": "en", "state": None},
    {"url": "https://indianexpress.com/section/lifestyle/health/feed/", "source": "IE Health", "category": "health", "language": "en", "state": None},
    {"url": "https://www.news18.com/rss/health.xml", "source": "News18 Health", "category": "health", "language": "en", "state": None},
]

# Category list for the app
CATEGORIES = [
    {"id": "all", "name": "All", "icon": "newspaper"},
    {"id": "national", "name": "National", "icon": "flag"},
    {"id": "world", "name": "World", "icon": "globe"},
    {"id": "business", "name": "Business", "icon": "trending_up"},
    {"id": "sports", "name": "Sports", "icon": "sports_cricket"},
    {"id": "tech", "name": "Tech", "icon": "computer"},
    {"id": "entertainment", "name": "Entertainment", "icon": "movie"},
    {"id": "science", "name": "Science", "icon": "science"},
    {"id": "health", "name": "Health", "icon": "health_and_safety"},
]

# Map of regional sources to state codes
SOURCE_STATE_MAP = {
    "Dinamalar": "TN",
    "Daily Thanthi": "TN",
    "Eenadu": "AP",
    "Sakshi": "TS",
    "Prajavani": "KA",
    "Mathrubhumi": "KL",
    "Manorama Online": "KL",
    "Loksatta": "MH",
    "Anandabazar Patrika": "WB",
    "Divya Bhaskar": "GJ",
    "Ajit": "PB",
    "Amar Ujala UP": "UP",
    "Dainik Jagran UP": "UP",
    "Live Hindustan Delhi": "DL",
    "Amar Ujala Delhi": "DL",
    "Dainik Jagran Bihar": "BR",
    "Dainik Jagran Rajasthan": "RJ",
}
