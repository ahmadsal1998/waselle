#!/usr/bin/env python3
"""
Resize app icon to all required iOS sizes.
This script takes a source icon image and generates all required iOS icon sizes.
"""

from PIL import Image, ImageDraw
import os
import sys

def resize_icon(source_path, output_dir, size, filename):
    """Resize source image to specified size and save."""
    try:
        # Open source image
        source = Image.open(source_path)
        
        # Convert to RGB if needed (remove alpha for App Store icon if it's 1024x1024)
        if source.mode == 'RGBA' and size == 1024:
            # For App Store icon, ensure no transparency
            rgb_image = Image.new('RGB', source.size, (255, 255, 255))
            rgb_image.paste(source, mask=source.split()[3])  # Use alpha channel as mask
            source = rgb_image
        elif source.mode != 'RGB':
            source = source.convert('RGB')
        
        # Resize with high-quality resampling
        resized = source.resize((size, size), Image.Resampling.LANCZOS)
        
        # Save
        output_path = os.path.join(output_dir, filename)
        resized.save(output_path, 'PNG', optimize=True)
        print(f"  ✓ Created {filename} ({size}x{size})")
        return True
    except Exception as e:
        print(f"  ✗ Error creating {filename}: {e}")
        return False

def generate_all_icons_from_source(source_path):
    """Generate all required iOS icon sizes from source image."""
    
    if not os.path.exists(source_path):
        print(f"Error: Source image not found: {source_path}")
        return False
    
    # Verify source image
    try:
        source = Image.open(source_path)
        print(f"Source image: {source_path}")
        print(f"  Size: {source.size[0]}x{source.size[1]}")
        print(f"  Mode: {source.mode}")
    except Exception as e:
        print(f"Error: Cannot open source image: {e}")
        return False
    
    # Define all required icon sizes based on Contents.json
    icon_sizes = {
        # iPhone icons
        'Icon-App-20x20@2x.png': 40,   # 20x20 @2x = 40x40
        'Icon-App-20x20@3x.png': 60,   # 20x20 @3x = 60x60
        'Icon-App-29x29@1x.png': 29,   # 29x29 @1x = 29x29
        'Icon-App-29x29@2x.png': 58,   # 29x29 @2x = 58x58
        'Icon-App-29x29@3x.png': 87,   # 29x29 @3x = 87x87
        'Icon-App-40x40@2x.png': 80,   # 40x40 @2x = 80x80
        'Icon-App-40x40@3x.png': 120,  # 40x40 @3x = 120x120
        'Icon-App-60x60@2x.png': 120,  # 60x60 @2x = 120x120
        'Icon-App-60x60@3x.png': 180,  # 60x60 @3x = 180x180
        
        # iPad icons
        'Icon-App-20x20@1x.png': 20,   # 20x20 @1x = 20x20
        'Icon-App-40x40@1x.png': 40,   # 40x40 @1x = 40x40
        'Icon-App-76x76@1x.png': 76,   # 76x76 @1x = 76x76
        'Icon-App-76x76@2x.png': 152,  # 76x76 @2x = 152x152
        'Icon-App-83.5x83.5@2x.png': 167,  # 83.5x83.5 @2x = 167x167
        
        # App Store icon (must be RGB, no transparency)
        'Icon-App-1024x1024@1x.png': 1024,  # 1024x1024 @1x = 1024x1024
    }
    
    # Output directory
    output_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    
    # Create directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"\nGenerating {len(icon_sizes)} app icons from source...")
    print(f"Output directory: {output_dir}\n")
    
    success_count = 0
    # Generate each icon size
    for filename, size in icon_sizes.items():
        if resize_icon(source_path, output_dir, size, filename):
            success_count += 1
    
    print(f"\n✓ Successfully generated {success_count}/{len(icon_sizes)} icons")
    
    if success_count == len(icon_sizes):
        print(f"\n✅ All icons generated successfully!")
        print(f"  Location: {output_dir}")
        print(f"\nNext steps:")
        print(f"  1. Verify icons in Xcode: ios/Runner.xcworkspace")
        print(f"  2. Update App Store Connect with new 1024x1024 icon")
        print(f"  3. Build and upload new version to App Store")
        return True
    else:
        print(f"\n⚠️  Some icons failed to generate. Please check the errors above.")
        return False

if __name__ == '__main__':
    # Default source path
    default_source = 'assets/images/app_icon.png'
    
    # Allow custom source path as argument
    source_path = sys.argv[1] if len(sys.argv) > 1 else default_source
    
    if not os.path.exists(source_path):
        print(f"Error: Source image not found: {source_path}")
        print(f"\nUsage: python3 resize_app_icon.py [source_image_path]")
        print(f"Default: {default_source}")
        print(f"\nPlease provide the path to your icon image file.")
        sys.exit(1)
    
    success = generate_all_icons_from_source(source_path)
    sys.exit(0 if success else 1)

