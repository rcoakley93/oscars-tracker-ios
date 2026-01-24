#!/bin/bash
# Run all Maestro tests for OscarsTracker

set -e

# Ensure PATH includes Java and Maestro
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH:$HOME/.maestro/bin"

# Create screenshots directory
mkdir -p .maestro/screenshots

echo "🎬 Running OscarsTracker Maestro Tests"
echo "======================================="

# Check for test credentials
if [[ -z "$MAESTRO_TEST_EMAIL" ]] || [[ -z "$MAESTRO_TEST_PASSWORD" ]]; then
    echo ""
    echo "⚠️  Note: MAESTRO_TEST_EMAIL and MAESTRO_TEST_PASSWORD not set"
    echo "   Skipping login flow. Make sure you're already logged in."
    echo ""
else
    echo ""
    echo "▶️  Running: .maestro/00-login.yaml"
    maestro test ".maestro/00-login.yaml" || { echo "❌ Failed: login"; exit 1; }
    echo "✅ Passed: login"
fi

# Run each test flow (skip login and config)
for flow in .maestro/*.yaml; do
    if [[ "$flow" != *"config.yaml" ]] && [[ "$flow" != *"00-login.yaml" ]]; then
        echo ""
        echo "▶️  Running: $flow"
        maestro test "$flow" || { echo "❌ Failed: $flow"; exit 1; }
        echo "✅ Passed: $flow"
    fi
done

echo ""
echo "======================================="
echo "🎉 All tests passed!"
echo "📸 Screenshots saved to: .maestro/screenshots/"
