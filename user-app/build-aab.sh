#!/bin/bash

# Google Play AAB Build Script for Wassle User App
# This script builds the production AAB file for Google Play submission

set -e  # Exit on error

echo "🚀 Building Wassle User App AAB for Google Play..."
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check Flutter version
echo "📱 Flutter version:"
flutter --version
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    echo "⚠️  WARNING: android/key.properties not found!"
    echo "   You need to create a signing keystore first."
    echo "   Run: ./setup-keystore.sh"
    echo ""
    read -p "Continue with debug signing? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Build cancelled"
        exit 1
    fi
fi

# Build AAB
echo "🔨 Building AAB file (this may take a few minutes)..."
flutter build appbundle --release

# Check if build was successful
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo ""
    echo "✅ AAB build successful!"
    echo ""
    echo "📦 AAB File:"
    echo "   Location: build/app/outputs/bundle/release/app-release.aab"
    echo "   Size: $AAB_SIZE"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Upload to Google Play Console"
    echo "   2. Complete store listing with screenshots and graphics"
    echo ""
    
    # Show version info
    VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
    echo "📱 App Version: $VERSION"
    echo ""
else
    echo ""
    echo "❌ Build failed! Check the error messages above."
    exit 1
fi

echo ""
echo "✨ Done!"

