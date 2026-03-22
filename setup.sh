#!/bin/bash
# ============================================
# BharatBrief — Quick Setup Script
# ============================================

set -e

echo "🇮🇳 BharatBrief Setup"
echo "========================="

# --- Backend Setup ---
echo ""
echo "📦 Setting up Python backend..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
echo "✅ Backend dependencies installed"

# --- Admin Setup ---
echo ""
echo "📦 Setting up Admin panel..."
cd ../admin
pip install -r requirements.txt
echo "✅ Admin dependencies installed"

# --- Flutter Setup ---
echo ""
echo "📱 Setting up Flutter app..."
cd ../bharat_brief
if command -v flutter &> /dev/null; then
    flutter create . --org com.bharatbrief --project-name bharat_brief 2>/dev/null || true
    flutter pub get
    echo "✅ Flutter app ready"
else
    echo "⚠️  Flutter SDK not found. Install from https://flutter.dev/docs/get-started/install"
    echo "   Then run: cd bharat_brief && flutter create . --org com.bharatbrief --project-name bharat_brief && flutter pub get"
fi

# --- Env file ---
cd ..
if [ ! -f .env ]; then
    cp .env.example .env
    echo ""
    echo "📝 Created .env file — please fill in your API keys:"
    echo "   - GEMINI_API_KEY (from https://aistudio.google.com/apikey)"
    echo "   - BHASHINI credentials (from https://bhashini.gov.in)"
    echo "   - FIREBASE_CREDENTIALS_PATH (download from Firebase Console)"
    echo "   - ADMIN_PASSWORD"
fi

echo ""
echo "========================="
echo "✅ Setup complete!"
echo ""
echo "To start the backend:  cd backend && source venv/bin/activate && python run.py"
echo "To start the admin:    cd admin && python admin_app.py"
echo "To run the Flutter app: cd bharat_brief && flutter run"
echo ""
