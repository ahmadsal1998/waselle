# Language-Specific Images

This directory contains images that change based on the app's language setting.

## Directory Structure

```
assets/images/
├── ar/                    # Arabic images
│   └── whatsapp_verification.png
├── en/                    # English images
│   └── whatsapp_verification.png
└── whatsapp_verification.png  # Fallback image (if language-specific doesn't exist)
```

## How It Works

1. When the app language is set to Arabic (`ar`), it will look for images in `assets/images/ar/`
2. When the app language is set to English (`en`), it will look for images in `assets/images/en/`
3. If a language-specific image doesn't exist, it falls back to the default image in `assets/images/`

## Adding New Language-Specific Images

1. Create the image files for each language:
   - `assets/images/ar/your_image.png` (Arabic version)
   - `assets/images/en/your_image.png` (English version)

2. Use the `ImageUtils.getLocalizedImagePath()` function in your code:
   ```dart
   final imagePath = ImageUtils.getLocalizedImagePath(context, 'your_image.png');
   Image.asset(imagePath)
   ```

3. The image will automatically update when the user changes the app language.

## Current Images

- `whatsapp_verification.png` - WhatsApp verification image shown in the phone verification dialog

## Notes

- Images should have the same dimensions for consistency
- Use PNG format for best quality
- Ensure images are optimized for mobile devices

