#!/usr/bin/env python3
"""
Convert SVG with embedded base64 image to PNG
"""
import base64
import re
from PIL import Image
import io
import sys

def extract_base64_from_svg(svg_path):
    """Extract base64 image data from SVG file"""
    with open(svg_path, 'r') as f:
        svg_content = f.read()
    
    # Find base64 image data
    # Pattern: data:image/jpeg;base64,<base64_data>
    pattern = r'data:image/([^;]+);base64,([^"]+)'
    match = re.search(pattern, svg_content)
    
    if match:
        image_format = match.group(1)
        base64_data = match.group(2)
        return base64_data, image_format
    else:
        raise ValueError("No base64 image found in SVG")

def convert_svg_to_png(svg_path, png_path, size=1024):
    """Convert SVG with embedded image to PNG"""
    base64_data, image_format = extract_base64_from_svg(svg_path)
    
    # Decode base64
    image_data = base64.b64decode(base64_data)
    
    # Open image
    img = Image.open(io.BytesIO(image_data))
    
    # Convert to RGB if needed (remove alpha channel)
    if img.mode in ('RGBA', 'LA', 'P'):
        # Create white background
        rgb_img = Image.new('RGB', img.size, (255, 255, 255))
        if img.mode == 'P':
            img = img.convert('RGBA')
        rgb_img.paste(img, mask=img.split()[-1] if img.mode in ('RGBA', 'LA') else None)
        img = rgb_img
    elif img.mode != 'RGB':
        img = img.convert('RGB')
    
    # Resize to desired size
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    
    # Save as PNG
    img.save(png_path, 'PNG', optimize=True)
    print(f"✓ Converted {svg_path} to {png_path} ({size}x{size})")

if __name__ == '__main__':
    svg_path = 'assets/images/app_icon.svg'
    png_path = 'assets/images/app_icon.png'
    
    try:
        convert_svg_to_png(svg_path, png_path, size=1024)
        print(f"\n✓ Successfully converted SVG to PNG")
        print(f"  Source: {svg_path}")
        print(f"  Output: {png_path}")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

