#!/usr/bin/env python3
"""
Scrape All Pages Wrapper Script
Reads pages from pages_config.json and scrapes them sequentially
"""

import json
import subprocess
import sys
from pathlib import Path


def scrape_all_pages(specific_page=None):
    """
    Scrape all pages from config or a specific page

    Args:
        specific_page: Optional slug to scrape only one page, or 'all' for all pages
    """
    config_file = Path(__file__).parent / "pages_config.json"

    if not config_file.exists():
        print(f"❌ Config file not found: {config_file}")
        print("   Please create pages_config.json with your LinkedIn pages")
        sys.exit(1)

    with open(config_file) as f:
        config = json.load(f)

    pages = config['pages']

    # Filter to specific page if requested
    if specific_page and specific_page != 'all':
        pages = [p for p in pages if p['slug'] == specific_page]
        if not pages:
            print(f"❌ Page '{specific_page}' not found in config")
            print(f"   Available pages: {', '.join([p['slug'] for p in config['pages']])}")
            sys.exit(1)

    print("=" * 60)
    print(f"🚀 LinkedIn Feed Scraper - Processing {len(pages)} page(s)")
    print("=" * 60)
    print()

    success_count = 0
    failed_pages = []

    for i, page in enumerate(pages, 1):
        print(f"[{i}/{len(pages)}] 📄 {page['name']} ({page['slug']})")
        print("-" * 60)

        # Run scraper
        print(f"  🔍 Scraping posts...")
        result = subprocess.run(
            ['python3', 'linkedin_scraper.py', page['url']],
            capture_output=False
        )

        if result.returncode != 0:
            print(f"  ❌ Failed to scrape {page['slug']}")
            failed_pages.append(page['slug'])
            print()
            continue

        # Generate RSS
        print(f"  📡 Generating RSS feed...")
        result = subprocess.run(
            ['python3', 'generate_rss.py', page['slug']],
            capture_output=False
        )

        if result.returncode != 0:
            print(f"  ❌ Failed to generate RSS for {page['slug']}")
            failed_pages.append(page['slug'])
        else:
            success_count += 1
            print(f"  ✅ Completed: {page['slug']}")

        print()

    # Summary
    print("=" * 60)
    print("📊 SUMMARY")
    print("=" * 60)
    print(f"✅ Success: {success_count}/{len(pages)} pages")
    if failed_pages:
        print(f"❌ Failed: {', '.join(failed_pages)}")
    print("=" * 60)

    return 0 if success_count == len(pages) else 1


if __name__ == "__main__":
    page = sys.argv[1] if len(sys.argv) > 1 else 'all'
    exit_code = scrape_all_pages(page)
    sys.exit(exit_code)
