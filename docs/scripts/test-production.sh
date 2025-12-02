#!/bin/bash

# Script to test production build locally with correct baseURL structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$DOCS_ROOT/.output/public"
TEST_DIR="$DOCS_ROOT/dist-test"

echo "🧪 Testing production build with GitHub Pages structure..."
echo ""

# Check if dist exists
if [ ! -d "$DIST_DIR" ]; then
  echo "❌ Error: dist/ directory not found!"
  echo "   Run 'npm run generate' first in docs/ directory"
  exit 1
fi

# Clean and create test structure
echo "📁 Creating test structure..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/raspberry-builds"

# Copy dist contents to raspberry-builds subdirectory
echo "📋 Copying files..."
cp -r "$DIST_DIR"/* "$TEST_DIR/raspberry-builds/"

echo "✅ Test structure created!"
echo ""
echo "📂 Structure:"
echo "   $TEST_DIR/"
echo "   └── raspberry-builds/"
echo "       ├── index.html"
echo "       ├── _nuxt/"
echo "       └── ..."
echo ""
echo "🚀 Starting server..."
echo ""
echo "   URL: http://localhost:3000/raspberry-builds/"
echo ""
echo "   Press Ctrl+C to stop"
echo ""

# Start server
cd "$TEST_DIR"
npx serve -p 3000