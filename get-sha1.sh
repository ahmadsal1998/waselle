#!/bin/bash

# Simple script to get SHA-1 fingerprint from a keystore
# Usage: ./get-sha1.sh <keystore-path> <alias>

if [ $# -lt 2 ]; then
    echo "Usage: $0 <keystore-path> <alias>"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/keystore.jks mykeyalias"
    echo ""
    echo "You will be prompted for the keystore password."
    exit 1
fi

KEYSTORE_PATH=$1
ALIAS=$2

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "Error: Keystore file not found: $KEYSTORE_PATH"
    exit 1
fi

echo "Getting SHA-1 fingerprint from keystore..."
echo "Keystore: $KEYSTORE_PATH"
echo "Alias: $ALIAS"
echo ""

# Get SHA-1 fingerprint
SHA1=$(keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$ALIAS" 2>/dev/null | grep -A 1 "SHA1:" | grep -o "[0-9A-F:]\{47\}" | head -1)

if [ -z "$SHA1" ]; then
    echo "Error: Could not extract SHA-1 fingerprint."
    echo "Please verify:"
    echo "  1. The keystore path is correct"
    echo "  2. The alias is correct"
    echo "  3. You entered the correct password"
    exit 1
fi

echo "=========================================="
echo "SHA-1 Fingerprint:"
echo "$SHA1"
echo "=========================================="
echo ""
echo "To add this SHA-1 to Firebase, run:"
echo ""
echo "For User App:"
echo "  firebase apps:android:sha:create 1:365868224840:android:8c4c2a41c8ef5d8bd1237d \"$SHA1\" --project wae-679cc"
echo ""
echo "For Driver App:"
echo "  firebase apps:android:sha:create 1:365868224840:android:c4f47331b713292ed1237d \"$SHA1\" --project wae-679cc"
echo ""

