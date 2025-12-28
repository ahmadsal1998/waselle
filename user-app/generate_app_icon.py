#!/usr/bin/env python3
"""
Generate unique app icon for Wassle delivery app.
This script creates a modern, distinctive icon that meets Apple's uniqueness requirements.
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

def create_icon(size):
    """
    Create a unique app icon for Wassle delivery app.
    Design: Modern geometric delivery box with gradient background.
    """
    # Create image with transparent background initially
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # Define unique color scheme - gradient from vibrant teal to deep purple
    # This is different from common delivery app colors (red, blue, yellow)
    color1 = (34, 193, 195)  # Vibrant teal
    color2 = (183, 33, 255)  # Deep purple
    color3 = (255, 119, 48)  # Vibrant orange accent
    
    # Create gradient background
    for y in range(size):
        ratio = y / size
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    # Draw unique geometric delivery box design
    # Using a modern, stylized box with a distinctive "W" integration
    center_x, center_y = size // 2, size // 2
    box_size = int(size * 0.5)
    
    # Draw main box shape with perspective (isometric style)
    box_points = [
        # Front face
        (center_x - box_size * 0.4, center_y - box_size * 0.2),
        (center_x + box_size * 0.4, center_y - box_size * 0.2),
        (center_x + box_size * 0.4, center_y + box_size * 0.3),
        (center_x - box_size * 0.4, center_y + box_size * 0.3),
    ]
    
    # Draw box with gradient fill
    for i, point in enumerate(box_points):
        if i < len(box_points) - 1:
            next_point = box_points[i + 1]
        else:
            next_point = box_points[0]
        
        # Create gradient effect on box
        steps = 20
        for step in range(steps):
            t = step / steps
            x1 = int(point[0] * (1 - t) + next_point[0] * t)
            y1 = int(point[1] * (1 - t) + next_point[1] * t)
            x2 = int(point[0] * (1 - (t + 1/steps)) + next_point[0] * (t + 1/steps))
            y2 = int(point[1] * (1 - (t + 1/steps)) + next_point[1] * (t + 1/steps))
            
            # Gradient from white to color3
            r = int(255 * (1 - t) + color3[0] * t)
            g = int(255 * (1 - t) + color3[1] * t)
            b = int(255 * (1 - t) + color3[2] * t)
            draw.line([(x1, y1), (x2, y2)], fill=(r, g, b), width=max(2, size // 50))
    
    # Draw top face of box (isometric perspective)
    top_points = [
        (center_x - box_size * 0.4, center_y - box_size * 0.2),
        (center_x - box_size * 0.2, center_y - box_size * 0.4),
        (center_x + box_size * 0.2, center_y - box_size * 0.4),
        (center_x + box_size * 0.4, center_y - box_size * 0.2),
    ]
    
    # Fill top face with lighter gradient
    for i in range(len(top_points)):
        p1 = top_points[i]
        p2 = top_points[(i + 1) % len(top_points)]
        steps = 15
        for step in range(steps):
            t = step / steps
            x1 = int(p1[0] * (1 - t) + p2[0] * t)
            y1 = int(p1[1] * (1 - t) + p2[1] * t)
            
            # Lighter orange/white gradient
            r = int(255 * (1 - t * 0.5) + color3[0] * t * 0.5)
            g = int(255 * (1 - t * 0.5) + color3[1] * t * 0.5)
            b = int(255 * (1 - t * 0.5) + color3[2] * t * 0.5)
            draw.line([(x1, y1), (center_x, center_y - box_size * 0.3)], 
                     fill=(r, g, b), width=max(1, size // 60))
    
    # Draw distinctive "W" letter integrated into the box design
    # Using modern, geometric style
    w_size = int(box_size * 0.6)
    w_x = center_x
    w_y = center_y + box_size * 0.05
    
    # Draw stylized "W" with thick strokes
    stroke_width = max(3, size // 30)
    
    # Left leg of W
    draw.line([(w_x - w_size * 0.35, w_y - w_size * 0.15),
               (w_x - w_size * 0.35, w_y + w_size * 0.15)],
              fill=(255, 255, 255), width=stroke_width)
    
    # Middle V of W
    draw.line([(w_x - w_size * 0.35, w_y + w_size * 0.15),
               (w_x, w_y - w_size * 0.05)],
              fill=(255, 255, 255), width=stroke_width)
    draw.line([(w_x, w_y - w_size * 0.05),
               (w_x + w_size * 0.35, w_y + w_size * 0.15)],
              fill=(255, 255, 255), width=stroke_width)
    
    # Right leg of W
    draw.line([(w_x + w_size * 0.35, w_y - w_size * 0.15),
               (w_x + w_size * 0.35, w_y + w_size * 0.15)],
              fill=(255, 255, 255), width=stroke_width)
    
    # Add decorative delivery arrow/checkmark on the side
    arrow_size = int(box_size * 0.25)
    arrow_x = center_x + box_size * 0.5
    arrow_y = center_y - box_size * 0.1
    
    # Draw checkmark style arrow
    check_width = max(2, size // 40)
    draw.line([(arrow_x - arrow_size * 0.3, arrow_y),
               (arrow_x - arrow_size * 0.1, arrow_y + arrow_size * 0.2)],
              fill=(255, 255, 255), width=check_width)
    draw.line([(arrow_x - arrow_size * 0.1, arrow_y + arrow_size * 0.2),
               (arrow_x + arrow_size * 0.3, arrow_y - arrow_size * 0.2)],
              fill=(255, 255, 255), width=check_width)
    
    # Add subtle shadow/highlight effects for depth
    # Top highlight
    highlight_y = int(size * 0.15)
    for y in range(highlight_y, highlight_y + int(size * 0.1)):
        alpha = 1.0 - (y - highlight_y) / (size * 0.1)
        r = int(255 * alpha + img.getpixel((center_x, y))[0] * (1 - alpha))
        g = int(255 * alpha + img.getpixel((center_x, y))[1] * (1 - alpha))
        b = int(255 * alpha + img.getpixel((center_x, y))[2] * (1 - alpha))
        draw.ellipse([(center_x - size * 0.3, y - 2), 
                     (center_x + size * 0.3, y + 2)],
                    fill=(r, g, b))
    
    return img

def generate_all_icons():
    """Generate all required iOS icon sizes."""
    
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
        'Icon-App-20x20@2x.png': 40,   # 20x20 @2x = 40x40 (iPad)
        'Icon-App-40x40@1x.png': 40,   # 40x40 @1x = 40x40
        'Icon-App-40x40@2x.png': 80,   # 40x40 @2x = 80x80 (iPad)
        'Icon-App-76x76@1x.png': 76,   # 76x76 @1x = 76x76
        'Icon-App-76x76@2x.png': 152,  # 76x76 @2x = 152x152
        'Icon-App-83.5x83.5@2x.png': 167,  # 83.5x83.5 @2x = 167x167
        
        # App Store icon
        'Icon-App-1024x1024@1x.png': 1024,  # 1024x1024 @1x = 1024x1024
    }
    
    # Output directory
    output_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    
    # Create directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Generating {len(icon_sizes)} app icons...")
    
    # Generate each icon size
    for filename, size in icon_sizes.items():
        print(f"  Creating {filename} ({size}x{size})...")
        icon = create_icon(size)
        output_path = os.path.join(output_dir, filename)
        icon.save(output_path, 'PNG', optimize=True)
        print(f"    ✓ Saved to {output_path}")
    
    print(f"\n✓ All icons generated successfully!")
    print(f"  Location: {output_dir}")
    print(f"\nNext steps:")
    print(f"  1. Verify icons in Xcode: ios/Runner.xcworkspace")
    print(f"  2. Update App Store Connect with new 1024x1024 icon")
    print(f"  3. Build and upload new version to App Store")

if __name__ == '__main__':
    try:
        generate_all_icons()
    except ImportError:
        print("Error: PIL (Pillow) is required.")
        print("Install it with: pip install Pillow")
        exit(1)
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

