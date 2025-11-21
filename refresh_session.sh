#!/bin/bash

# Refresh LinkedIn Session Script
# This script helps you easily update your LinkedIn session when it expires

set -e  # Exit on error

echo "==============================================================="
echo "🔄 LinkedIn Session Refresh Script"
echo "==============================================================="
echo ""
echo "This script will:"
echo "  1. Run the scraper to refresh your LinkedIn session"
echo "  2. Re-encrypt the session file"
echo "  3. Commit and push to GitHub"
echo ""
echo "💡 A browser window will open - log in to LinkedIn if prompted"
echo ""

# Check if encryption key is provided
ENCRYPTION_KEY="${1:-$SESSION_ENCRYPTION_KEY}"

if [ -z "$ENCRYPTION_KEY" ]; then
    echo "❌ Error: Encryption key required"
    echo ""
    echo "Usage: ./refresh_session.sh YOUR_ENCRYPTION_KEY"
    echo "   or: SESSION_ENCRYPTION_KEY=your_key ./refresh_session.sh"
    echo ""
    exit 1
fi

# Get the first page from config to use for session refresh
FIRST_PAGE_URL=$(python3 -c "
import json
with open('pages_config.json') as f:
    config = json.load(f)
    print(config['pages'][0]['url'])
")

echo "📄 Using first page from config for session refresh..."
echo ""

# Run scraper with browser visible (HEADLESS=false)
echo "🚀 Starting scraper (browser will be visible)..."
export HEADLESS=false
python3 linkedin_scraper.py "$FIRST_PAGE_URL"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Scraper failed - session may not have been updated"
    exit 1
fi

echo ""
echo "✅ Scraper completed successfully"
echo ""

# Check if session file exists
if [ ! -f "browser_state/linkedin_state.json" ]; then
    echo "❌ Session file not found - login may have failed"
    exit 1
fi

# Encrypt the session
echo "🔒 Encrypting session..."
openssl enc -aes-256-cbc -salt -pbkdf2 \
    -in browser_state/linkedin_state.json \
    -out browser_state/linkedin_state.json.enc \
    -k "$ENCRYPTION_KEY"

if [ $? -ne 0 ]; then
    echo "❌ Encryption failed"
    exit 1
fi

echo "✅ Session encrypted"
echo ""

# Commit and push to GitHub
echo "📤 Committing and pushing to GitHub..."
git add browser_state/linkedin_state.json.enc

if git diff --staged --quiet; then
    echo "⚠️  No changes to session file - already up to date"
else
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    git commit -m "Update LinkedIn session - ${TIMESTAMP}"
    git push
    echo "✅ Session pushed to GitHub"
fi

echo ""
echo "==============================================================="
echo "✅ Session refresh complete!"
echo "==============================================================="
echo ""
echo "Your GitHub Actions workflow can now use the updated session."
echo ""
