#!/bin/bash

# iOS TestFlight Build Script with Review Mode
# This script prepares and builds the iOS app for TestFlight submission
# Review Mode will automatically activate when running from TestFlight

set -e  # Exit on error

echo "🚀 Starting iOS TestFlight Build Preparation..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}📁 Project Directory:${NC} $PROJECT_DIR"
echo ""

# Step 1: Check Flutter installation
echo -e "${BLUE}Step 1: Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi
flutter --version
echo ""

# Step 2: Check current version
echo -e "${BLUE}Step 2: Checking current version...${NC}"
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo -e "${GREEN}Current version:${NC} $VERSION"
echo ""

# Step 3: Clean previous builds
echo -e "${BLUE}Step 3: Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean completed${NC}"
echo ""

# Step 4: Get Flutter dependencies
echo -e "${BLUE}Step 4: Getting Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 5: Update CocoaPods
echo -e "${BLUE}Step 5: Updating CocoaPods dependencies...${NC}"
cd ios
if ! command -v pod &> /dev/null; then
    echo -e "${YELLOW}⚠️  CocoaPods not found. Installing...${NC}"
    sudo gem install cocoapods
fi

# Clean CocoaPods cache (optional but recommended)
echo "Cleaning CocoaPods cache..."
rm -rf Pods Podfile.lock

# Install/update pods
echo "Installing CocoaPods dependencies..."
pod install --repo-update
echo -e "${GREEN}✅ CocoaPods updated${NC}"
cd ..
echo ""

# Step 6: Verify Review Mode configuration
echo -e "${BLUE}Step 6: Verifying Review Mode configuration...${NC}"
if grep -q "ReviewModeService" lib/main.dart; then
    echo -e "${GREEN}✅ Review Mode service found${NC}"
else
    echo -e "${YELLOW}⚠️  Review Mode service not found in main.dart${NC}"
fi

if grep -q "isTestFlight" ios/Runner/AppDelegate.swift; then
    echo -e "${GREEN}✅ TestFlight detection found in AppDelegate${NC}"
else
    echo -e "${YELLOW}⚠️  TestFlight detection not found in AppDelegate${NC}"
fi
echo ""

# Step 7: Build iOS (Release mode)
echo -e "${BLUE}Step 7: Building iOS app (Release mode)...${NC}"
echo -e "${YELLOW}Note: Review Mode will automatically activate in TestFlight via runtime detection${NC}"
echo ""

# Build with optional TESTFLIGHT flag (fallback method)
# Runtime detection is primary, but this ensures it works even if runtime detection fails
echo "Building with Flutter CLI..."
flutter build ios --release --dart-define=TESTFLIGHT=true

echo ""
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo ""

# Step 8: Instructions for Xcode
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Build Preparation Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Open Xcode:"
echo "   cd ios && open Runner.xcworkspace"
echo ""
echo "2. In Xcode:"
echo "   - Select 'Any iOS Device' or a connected device"
echo "   - Go to Product → Archive"
echo "   - Wait for archive to complete"
echo ""
echo "3. Upload to TestFlight:"
echo "   - In Organizer window, click 'Distribute App'"
echo "   - Select 'App Store Connect'"
echo "   - Follow the distribution wizard"
echo ""
echo "4. Review Mode will automatically activate when:"
echo "   - App is installed from TestFlight"
echo "   - App detects TestFlight environment at runtime"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - Review Mode uses runtime detection (primary method)"
echo "  - No manual configuration needed in Xcode"
echo "  - Review Mode will NOT activate in App Store releases"
echo ""
echo -e "${GREEN}Build ready for TestFlight submission! 🎉${NC}"

