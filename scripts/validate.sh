#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔍 Running validation..."

# Run the Playwright tests (which validate iOS project structure and build)
cd "$PROJECT_ROOT"
npx playwright test

echo "✅ Validation complete!"
