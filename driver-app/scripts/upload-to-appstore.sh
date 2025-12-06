#!/bin/bash

# Upload to App Store Script
# This script helps upload the iOS app to App Store Connect using xcodebuild
# Note: You may need to use Xcode Organizer or Transporter for final upload

set -e  # Exit on error

echo "📤 Uploading Driver App to App Store Connect"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
IOS_DIR="$PROJECT_DIR/ios"
ARCHIVE_PATH="$IOS_DIR/build/Runner.xcarchive"
EXPORT_PATH="$IOS_DIR/build/export"

echo ""
echo "📁 Project Directory: $PROJECT_DIR"
echo "📁 iOS Directory: $IOS_DIR"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed or xcodebuild is not in PATH${NC}"
    exit 1
fi

# Check if archive exists
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${YELLOW}⚠️  Archive not found at: $ARCHIVE_PATH${NC}"
    echo ""
    echo "Please create an archive first:"
    echo "   1. Open Xcode: cd ios && open Runner.xcworkspace"
    echo "   2. Select Product → Destination → Any iOS Device (arm64)"
    echo "   3. Select Product → Archive"
    echo ""
    echo "Or use the build script to create an archive:"
    echo "   ./scripts/build-archive.sh"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Archive found: $ARCHIVE_PATH${NC}"
echo ""

# Get team ID (optional, can be passed as argument)
TEAM_ID="${1:-}"

if [ -z "$TEAM_ID" ]; then
    echo -e "${YELLOW}⚠️  Team ID not provided${NC}"
    echo "You can provide it as an argument: ./upload-to-appstore.sh YOUR_TEAM_ID"
    echo ""
    echo "Finding available teams..."
    xcodebuild -showBuildSettings -project "$IOS_DIR/Runner.xcodeproj" 2>/dev/null | grep "DEVELOPMENT_TEAM" || true
    echo ""
    read -p "Enter your Team ID (or press Enter to use automatic signing): " TEAM_ID
fi

# Create export options plist
EXPORT_OPTIONS_PLIST="$IOS_DIR/ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>destination</key>
    <string>upload</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

echo -e "${BLUE}📝 Export options created: $EXPORT_OPTIONS_PLIST${NC}"
echo ""

# Export IPA
echo "📦 Exporting IPA..."
cd "$IOS_DIR"

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ IPA exported successfully!${NC}"
    echo ""
    IPA_PATH="$EXPORT_PATH/Runner.ipa"
    
    if [ -f "$IPA_PATH" ]; then
        echo "📱 IPA location: $IPA_PATH"
        echo ""
        echo "📤 Upload options:"
        echo ""
        echo "Option 1: Use Transporter App (Recommended)"
        echo "   1. Open Transporter app (download from Mac App Store)"
        echo "   2. Drag and drop: $IPA_PATH"
        echo "   3. Click 'Deliver'"
        echo ""
        echo "Option 2: Use Xcode Organizer"
        echo "   1. Open Xcode"
        echo "   2. Window → Organizer"
        echo "   3. Select your archive"
        echo "   4. Click 'Distribute App'"
        echo ""
        echo "Option 3: Use altool (Deprecated, use Transporter instead)"
        echo "   xcrun altool --upload-app --type ios --file \"$IPA_PATH\" --username YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD"
        echo ""
    else
        echo -e "${YELLOW}⚠️  IPA file not found at expected location${NC}"
    fi
else
    echo ""
    echo -e "${RED}❌ Export failed!${NC}"
    echo "Please check the error messages above."
    exit 1
fi

# Clean up export options plist (optional)
read -p "Delete export options plist? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm "$EXPORT_OPTIONS_PLIST"
    echo -e "${GREEN}✅ Export options plist deleted${NC}"
fi

echo ""
echo -e "${GREEN}✅ Upload preparation complete!${NC}"
echo ""

