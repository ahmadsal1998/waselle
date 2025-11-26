#!/bin/bash

# Script to list existing SHA-1 fingerprints in Firebase
# Usage: ./list-firebase-sha1.sh

PROJECT_ID="wae-679cc"
USER_APP_ID="1:365868224840:android:8c4c2a41c8ef5d8bd1237d"
DRIVER_APP_ID="1:365868224840:android:c4f47331b713292ed1237d"

echo "=========================================="
echo "Firebase SHA-1 Fingerprints"
echo "=========================================="
echo "Project: $PROJECT_ID"
echo ""

echo "User App (com.wassle.userapp):"
echo "App ID: $USER_APP_ID"
echo "----------------------------------------"
firebase apps:android:sha:list "$USER_APP_ID" --project "$PROJECT_ID" 2>/dev/null || echo "No SHA-1 fingerprints found or error occurred"
echo ""

echo "Driver App (com.wassle.driverapp):"
echo "App ID: $DRIVER_APP_ID"
echo "----------------------------------------"
firebase apps:android:sha:list "$DRIVER_APP_ID" --project "$PROJECT_ID" 2>/dev/null || echo "No SHA-1 fingerprints found or error occurred"
echo ""

echo "=========================================="

