# Account Deletion Web Page - Instructions

## Overview

This page is required for Google Play's Data Safety section. It provides users with information about how to delete their account from the Wassle Driver app.

## Files Created

1. **`delete-account.html`** - Full-featured version with detailed instructions
2. **`delete-account-simple.html`** - Minimal version (as per your example)

## Deployment

### URL Requirements

Google Play requires a publicly accessible URL. You can use:

- **Primary URL:** `https://wassleapp.com/delete-account`
- **Alternative:** `https://www.wassle.ps/delete-account`

### Hosting Options

1. **Your existing website** (wassleapp.com or wassle.ps)
   - Upload the HTML file to your web server
   - Place it at: `/delete-account` or `/delete-account.html`

2. **Static hosting services:**
   - GitHub Pages
   - Netlify
   - Vercel
   - Firebase Hosting

### Quick Deployment Example

If using a simple web server:

```bash
# Upload delete-account.html to your web server
# Ensure it's accessible at: https://wassleapp.com/delete-account
```

## Google Play Console Setup

1. Go to Google Play Console
2. Navigate to your app → **Policy** → **App content**
3. Scroll to **Data safety** section
4. Find **Data deletion** section
5. Enter the URL: `https://wassleapp.com/delete-account`
6. Save and submit

## Content Verification

The page includes:
- ✅ Instructions on how to delete account from app
- ✅ OTP verification process explained
- ✅ Warning about permanent deletion
- ✅ Support contact information
- ✅ Mobile-friendly design
- ✅ Simple HTML/CSS (no frameworks)

## Customization

### Update Support Email

If your support email is different, update in both HTML files:

```html
<a href="mailto:support@wassleapp.com">support@wassleapp.com</a>
```

### Update Domain

If using a different domain, update all references:
- `wassleapp.com` → your domain
- `wassle.ps` → your domain

### Add App Store Links (Optional)

You can add links to download the app:

```html
<a href="https://play.google.com/store/apps/details?id=com.wassle.driverapp">
  Download Wassle Driver
</a>
```

## Testing

Before submitting to Google Play:

1. ✅ Verify URL is accessible
2. ✅ Test on mobile devices
3. ✅ Check all links work
4. ✅ Verify email link opens correctly
5. ✅ Ensure page loads quickly

## Maintenance

- Keep the page updated if account deletion process changes
- Update support email if it changes
- Ensure URL remains accessible

---

**Next Step:** Upload the HTML file to your web server and add the URL to Google Play Console's Data Safety section.

