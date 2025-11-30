#!/bin/bash

# Keystore Setup Script for Wassle User App
# This script helps you create a signing keystore for Google Play

set -e

echo "🔐 Setting up signing keystore for Wassle User App"
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool is not installed or not in PATH"
    echo "   keytool comes with Java JDK. Please install Java JDK first."
    exit 1
fi

# Set keystore location (in user's home directory for security)
KEYSTORE_PATH="$HOME/wassle-user-keystore.jks"
KEYSTORE_DIR="$(dirname "$KEYSTORE_PATH")"

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Keystore already exists at: $KEYSTORE_PATH"
    read -p "Do you want to create a new one? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing keystore..."
        EXISTING_KEYSTORE=true
    else
        echo "⚠️  WARNING: Creating a new keystore will invalidate the old one!"
        echo "   If you've already published the app, you CANNOT use a new keystore!"
        read -p "Are you sure you want to create a new keystore? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
        EXISTING_KEYSTORE=false
    fi
else
    EXISTING_KEYSTORE=false
fi

# Create keystore if it doesn't exist
if [ "$EXISTING_KEYSTORE" = false ]; then
    echo ""
    echo "📝 Creating new keystore..."
    echo "   Location: $KEYSTORE_PATH"
    echo ""
    echo "You will be prompted for:"
    echo "  - Keystore password (remember this!)"
    echo "  - Key password (usually same as keystore password)"
    echo "  - Your name and organization details"
    echo ""
    echo "⚠️  IMPORTANT: Save these passwords securely!"
    echo ""
    
    keytool -genkey -v \
        -keystore "$KEYSTORE_PATH" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -alias wassle-user
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Keystore created successfully!"
    else
        echo ""
        echo "❌ Failed to create keystore"
        exit 1
    fi
fi

# Get passwords for key.properties
echo ""
echo "📝 Creating key.properties file..."
echo ""

if [ "$EXISTING_KEYSTORE" = false ]; then
    read -sp "Enter keystore password: " STORE_PASSWORD
    echo
    read -sp "Enter key password (or press Enter to use same as keystore): " KEY_PASSWORD
    echo
    
    if [ -z "$KEY_PASSWORD" ]; then
        KEY_PASSWORD="$STORE_PASSWORD"
    fi
else
    echo "Enter keystore password:"
    read -sp "Keystore password: " STORE_PASSWORD
    echo
    read -sp "Key password (or press Enter to use same): " KEY_PASSWORD
    echo
    
    if [ -z "$KEY_PASSWORD" ]; then
        KEY_PASSWORD="$STORE_PASSWORD"
    fi
fi

# Create key.properties file
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEY_PROPERTIES_FILE="$PROJECT_DIR/android/key.properties"

cat > "$KEY_PROPERTIES_FILE" << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=wassle-user
storeFile=$KEYSTORE_PATH
EOF

echo ""
echo "✅ key.properties file created at: $KEY_PROPERTIES_FILE"
echo ""

# Update .gitignore
GITIGNORE_FILE="$PROJECT_DIR/.gitignore"
if ! grep -q "key.properties" "$GITIGNORE_FILE" 2>/dev/null; then
    echo "" >> "$GITIGNORE_FILE"
    echo "# Android signing" >> "$GITIGNORE_FILE"
    echo "android/key.properties" >> "$GITIGNORE_FILE"
    echo "*.jks" >> "$GITIGNORE_FILE"
    echo "*.keystore" >> "$GITIGNORE_FILE"
    echo "✅ Updated .gitignore to exclude keystore files"
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "📋 Summary:"
echo "   Keystore: $KEYSTORE_PATH"
echo "   Key properties: $KEY_PROPERTIES_FILE"
echo ""
echo "⚠️  IMPORTANT:"
echo "   1. Backup your keystore file: $KEYSTORE_PATH"
echo "   2. Save your passwords securely"
echo "   3. If you lose the keystore, you cannot update your app on Google Play!"
echo ""
echo "🚀 Next step: Run ./build-aab.sh to build your AAB file"

