#!/bin/bash

# Build iOS Release Script for Driver App
# This script builds the iOS app for App Store submission

set -e  # Exit on error

echo "🚀 Building iOS Release for Driver App"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
IOS_DIR="$PROJECT_DIR/ios"

echo ""
echo "📁 Project Directory: $PROJECT_DIR"
echo "📁 iOS Directory: $IOS_DIR"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Check Flutter version
echo "🔍 Checking Flutter installation..."
flutter --version
echo ""

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
    echo -e "${RED}❌ pubspec.yaml not found. Are you in the driver-app directory?${NC}"
    exit 1
fi

# Check version from pubspec.yaml
VERSION=$(grep "^version:" "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | tr -d ' ')
echo "📱 App Version: $VERSION"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
cd "$PROJECT_DIR"
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Clean iOS build
echo "🧹 Cleaning iOS build..."
cd "$IOS_DIR"
if [ -d "Pods" ]; then
    rm -rf Pods Podfile.lock
    echo -e "${GREEN}✅ CocoaPods cache cleared${NC}"
fi
echo ""

# Install CocoaPods dependencies
echo "📦 Installing CocoaPods dependencies..."
if ! command -v pod &> /dev/null; then
    echo -e "${YELLOW}⚠️  CocoaPods not found. Installing...${NC}"
    sudo gem install cocoapods
fi

pod install
echo -e "${GREEN}✅ CocoaPods dependencies installed${NC}"
echo ""

# Build iOS release
echo "🔨 Building iOS Release..."
cd "$PROJECT_DIR"
flutter build ios --release

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Open Xcode: cd ios && open Runner.xcworkspace"
    echo "   2. Select Product → Destination → Any iOS Device (arm64)"
    echo "   3. Select Product → Archive"
    echo "   4. In Organizer, click 'Distribute App'"
    echo "   5. Select 'App Store Connect' → 'Upload'"
    echo ""
    echo "📱 Build location: $PROJECT_DIR/build/ios/iphoneos/Runner.app"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Build failed!${NC}"
    echo "Please check the error messages above."
    exit 1
fi

