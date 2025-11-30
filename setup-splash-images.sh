#!/bin/bash

# Setup Splash Images Script
# This script helps you set up splash.png images for both driver-app and user-app

DRIVER_APP_BASE="/Users/ahmad/Desktop/Awsaltak/driver-app/android/app/src/main/res"
USER_APP_BASE="/Users/ahmad/Desktop/Awsaltak/user-app/android/app/src/main/res"

# Function to copy splash image to all density folders
copy_splash_to_all_densities() {
    local app_base=$1
    local source_file=$2
    
    if [ ! -f "$source_file" ]; then
        echo "Error: Source file $source_file not found!"
        return 1
    fi
    
    echo "Copying splash.png to $app_base..."
    
    # Copy to all density folders
    cp "$source_file" "$app_base/drawable-mdpi/splash.png"
    cp "$source_file" "$app_base/drawable-hdpi/splash.png"
    cp "$source_file" "$app_base/drawable-xhdpi/splash.png"
    cp "$source_file" "$app_base/drawable-xxhdpi/splash.png"
    cp "$source_file" "$app_base/drawable-xxxhdpi/splash.png"
    
    echo "✓ Splash images copied successfully!"
    return 0
}

# Main script
if [ "$1" == "" ]; then
    echo "Usage: ./setup-splash-images.sh <path-to-splash.png>"
    echo ""
    echo "Example: ./setup-splash-images.sh ~/Desktop/splash.png"
    echo ""
    echo "This will copy the splash.png to all density folders in both apps."
    exit 1
fi

SPLASH_FILE=$1

if [ ! -f "$SPLASH_FILE" ]; then
    echo "Error: File $SPLASH_FILE does not exist!"
    exit 1
fi

echo "Setting up splash images for both apps..."
echo "Source file: $SPLASH_FILE"
echo ""

# Copy to driver-app
echo "1. Copying to driver-app..."
copy_splash_to_all_densities "$DRIVER_APP_BASE" "$SPLASH_FILE"

echo ""

# Copy to user-app
echo "2. Copying to user-app..."
copy_splash_to_all_densities "$USER_APP_BASE" "$SPLASH_FILE"

echo ""
echo "✓ All splash images have been set up!"
echo ""
echo "Note: For best results, you should create density-specific versions:"
echo "  - mdpi: 48x48dp"
echo "  - hdpi: 72x72dp"
echo "  - xhdpi: 96x96dp"
echo "  - xxhdpi: 144x144dp"
echo "  - xxxhdpi: 192x192dp"
echo ""
echo "You can use online tools like https://appicon.co or Android Studio's Asset Studio"

