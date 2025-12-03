#!/bin/bash

# Review Mode Setup Verification Script
# This script verifies that Review Mode is properly configured for TestFlight

set -e

echo "🔍 Verifying Review Mode Setup..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Get project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}Project Directory:${NC} $PROJECT_DIR"
echo ""

# Check 1: Review Mode Service exists
echo -e "${BLUE}Check 1: Review Mode Service${NC}"
if [ -f "lib/services/review_mode_service.dart" ]; then
    echo -e "${GREEN}✅ Review Mode Service found${NC}"
else
    echo -e "${RED}❌ Review Mode Service not found${NC}"
    ((ERRORS++))
fi

# Check 2: Review Mode Config exists
echo -e "${BLUE}Check 2: Review Mode Config${NC}"
if [ -f "lib/config/review_mode_config.dart" ]; then
    echo -e "${GREEN}✅ Review Mode Config found${NC}"
else
    echo -e "${RED}❌ Review Mode Config not found${NC}"
    ((ERRORS++))
fi

# Check 3: Mock Data exists
echo -e "${BLUE}Check 3: Review Mode Mock Data${NC}"
if [ -f "lib/services/review_mode_mock_data.dart" ]; then
    echo -e "${GREEN}✅ Review Mode Mock Data found${NC}"
else
    echo -e "${RED}❌ Review Mode Mock Data not found${NC}"
    ((ERRORS++))
fi

# Check 4: AppDelegate has TestFlight detection
echo -e "${BLUE}Check 4: iOS TestFlight Detection${NC}"
if grep -q "isTestFlight" ios/Runner/AppDelegate.swift; then
    echo -e "${GREEN}✅ TestFlight detection found in AppDelegate${NC}"
else
    echo -e "${RED}❌ TestFlight detection not found in AppDelegate${NC}"
    ((ERRORS++))
fi

if grep -q "sandboxReceipt" ios/Runner/AppDelegate.swift; then
    echo -e "${GREEN}✅ Sandbox receipt detection found${NC}"
else
    echo -e "${RED}❌ Sandbox receipt detection not found${NC}"
    ((ERRORS++))
fi

# Check 5: Method channel setup
echo -e "${BLUE}Check 5: Method Channel Setup${NC}"
if grep -q "com.wassle.userapp/testflight" ios/Runner/AppDelegate.swift; then
    echo -e "${GREEN}✅ Method channel name correct${NC}"
else
    echo -e "${RED}❌ Method channel name not found or incorrect${NC}"
    ((ERRORS++))
fi

# Check 6: View Models integration
echo -e "${BLUE}Check 6: View Models Integration${NC}"

if grep -q "ReviewModeService" lib/view_models/auth_view_model.dart; then
    echo -e "${GREEN}✅ AuthViewModel integrated${NC}"
else
    echo -e "${YELLOW}⚠️  AuthViewModel not integrated${NC}"
    ((WARNINGS++))
fi

if grep -q "ReviewModeService" lib/view_models/order_view_model.dart; then
    echo -e "${GREEN}✅ OrderViewModel integrated${NC}"
else
    echo -e "${YELLOW}⚠️  OrderViewModel not integrated${NC}"
    ((WARNINGS++))
fi

if grep -q "ReviewModeService" lib/view_models/driver_view_model.dart; then
    echo -e "${GREEN}✅ DriverViewModel integrated${NC}"
else
    echo -e "${YELLOW}⚠️  DriverViewModel not integrated${NC}"
    ((WARNINGS++))
fi

if grep -q "ReviewModeService" lib/view_models/location_view_model.dart; then
    echo -e "${GREEN}✅ LocationViewModel integrated${NC}"
else
    echo -e "${YELLOW}⚠️  LocationViewModel not integrated${NC}"
    ((WARNINGS++))
fi

# Check 7: Bundle ID
echo -e "${BLUE}Check 7: Bundle Identifier${NC}"
BUNDLE_ID=$(grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | grep "com.wassle.userapp" | head -1 | sed 's/.*= //' | sed 's/;//')
if [ "$BUNDLE_ID" = "com.wassle.userapp" ]; then
    echo -e "${GREEN}✅ Bundle ID correct: com.wassle.userapp${NC}"
else
    echo -e "${YELLOW}⚠️  Bundle ID: $BUNDLE_ID${NC}"
    ((WARNINGS++))
fi

# Check 8: Development Team
echo -e "${BLUE}Check 8: Development Team${NC}"
TEAM=$(grep "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | head -1 | sed 's/.*= //' | sed 's/;//')
if [ -n "$TEAM" ]; then
    echo -e "${GREEN}✅ Development Team configured: $TEAM${NC}"
else
    echo -e "${YELLOW}⚠️  Development Team not configured${NC}"
    ((WARNINGS++))
fi

# Check 9: Version
echo -e "${BLUE}Check 9: App Version${NC}"
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo -e "${GREEN}Current version:${NC} $VERSION"

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Review Mode is properly configured.${NC}"
    echo ""
    echo -e "${GREEN}Ready to build for TestFlight! 🚀${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Setup complete with $WARNINGS warning(s)${NC}"
    echo -e "${GREEN}Review Mode should work, but check warnings above.${NC}"
    exit 0
else
    echo -e "${RED}❌ Setup incomplete: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo -e "${RED}Please fix errors before building.${NC}"
    exit 1
fi

