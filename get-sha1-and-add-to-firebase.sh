#!/bin/bash

# Script to get Release SHA-1 fingerprints and add them to Firebase
# Usage: ./get-sha1-and-add-to-firebase.sh

set -e

echo "=========================================="
echo "Firebase SHA-1 Fingerprint Setup"
echo "=========================================="
echo ""

# Firebase project
PROJECT_ID="wae-679cc"

# App IDs from Firebase
USER_APP_ID="1:365868224840:android:8c4c2a41c8ef5d8bd1237d"
DRIVER_APP_ID="1:365868224840:android:c4f47331b713292ed1237d"

echo "This script will help you:"
echo "1. Get SHA-1 fingerprints from your release keystores"
echo "2. Add them to Firebase for both User and Driver apps"
echo ""
echo "Firebase Project: $PROJECT_ID"
echo "User App ID: $USER_APP_ID"
echo "Driver App ID: $DRIVER_APP_ID"
echo ""
echo "=========================================="
echo ""

# Function to get SHA-1 from keystore
get_sha1() {
    local keystore_path=$1
    local alias=$2
    
    echo "Getting SHA-1 fingerprint..."
    echo "Keystore: $keystore_path"
    echo "Alias: $alias"
    echo ""
    
    # Extract SHA-1 from keytool output
    SHA1=$(keytool -list -v -keystore "$keystore_path" -alias "$alias" 2>/dev/null | grep -A 1 "SHA1:" | grep -o "[0-9A-F:]\{47\}" | head -1)
    
    if [ -z "$SHA1" ]; then
        echo "Error: Could not extract SHA-1 fingerprint. Please check your keystore path and alias."
        return 1
    fi
    
    echo "SHA-1 Fingerprint: $SHA1"
    echo ""
    echo "$SHA1"
}

# Function to add SHA-1 to Firebase
add_sha_to_firebase() {
    local app_id=$1
    local sha1=$2
    local app_name=$3
    
    echo "Adding SHA-1 to Firebase for $app_name..."
    firebase apps:android:sha:create "$app_id" "$sha1" --project "$PROJECT_ID"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully added SHA-1 to Firebase for $app_name"
    else
        echo "✗ Failed to add SHA-1 to Firebase for $app_name"
        return 1
    fi
    echo ""
}

# USER APP
echo "=========================================="
echo "USER APP (com.wassle.userapp)"
echo "=========================================="
read -p "Enter the path to your User app release keystore: " USER_KEYSTORE
read -p "Enter the keystore alias: " USER_ALIAS

USER_SHA1=$(get_sha1 "$USER_KEYSTORE" "$USER_ALIAS")

if [ -n "$USER_SHA1" ]; then
    read -p "Add this SHA-1 to Firebase? (y/n): " CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        add_sha_to_firebase "$USER_APP_ID" "$USER_SHA1" "User App"
    else
        echo "Skipped adding SHA-1 to Firebase for User App"
    fi
fi

echo ""
echo "=========================================="
echo "DRIVER APP (com.wassle.driverapp)"
echo "=========================================="
read -p "Enter the path to your Driver app release keystore: " DRIVER_KEYSTORE
read -p "Enter the keystore alias: " DRIVER_ALIAS

DRIVER_SHA1=$(get_sha1 "$DRIVER_KEYSTORE" "$DRIVER_ALIAS")

if [ -n "$DRIVER_SHA1" ]; then
    read -p "Add this SHA-1 to Firebase? (y/n): " CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        add_sha_to_firebase "$DRIVER_APP_ID" "$DRIVER_SHA1" "Driver App"
    else
        echo "Skipped adding SHA-1 to Firebase for Driver App"
    fi
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "User App SHA-1: $USER_SHA1"
echo "Driver App SHA-1: $DRIVER_SHA1"
echo ""
echo "Done! You can verify the SHA-1 fingerprints in Firebase Console:"
echo "https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
echo ""

