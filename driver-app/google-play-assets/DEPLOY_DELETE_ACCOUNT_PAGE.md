# Deploy Delete Account Page to wassle.ps

## Current Status

The URL `https://www.wassle.ps/delete-account` is currently showing an empty page. You need to upload the HTML file to your web server.

## Files Ready for Upload

You have two versions of the delete account page:

1. **`delete-account.html`** - Full-featured version (recommended)
2. **`delete-account-simple.html`** - Minimal version

**Location:** `/Users/ahmad/Desktop/Awsaltak/driver-app/google-play-assets/`

## Deployment Steps

### Option 1: Upload via FTP/SFTP

1. **Connect to your web server** (wassle.ps hosting)
   - Use FTP client (FileZilla, Cyberduck, etc.)
   - Or use SSH/SFTP

2. **Upload the file:**
   - Upload `delete-account.html` to your web server
   - Place it in the root directory or appropriate folder
   - Ensure it's accessible at: `https://www.wassle.ps/delete-account`

3. **File naming options:**
   - **Option A:** Upload as `delete-account.html` and configure server to serve it at `/delete-account`
   - **Option B:** Upload to a folder like `/delete-account/index.html`
   - **Option C:** Configure server rewrite rules

### Option 2: Using cPanel/Web Hosting Panel

1. Log into your hosting control panel (cPanel, Plesk, etc.)
2. Navigate to File Manager
3. Go to your website's root directory (usually `public_html` or `www`)
4. Upload `delete-account.html`
5. Rename or configure to be accessible at `/delete-account`

### Option 3: Using SSH/Command Line

If you have SSH access to your server:

```bash
# Copy file to server
scp delete-account.html user@wassle.ps:/path/to/website/delete-account.html

# Or if using a folder structure
scp delete-account.html user@wassle.ps:/path/to/website/delete-account/index.html
```

## Server Configuration

### Apache (.htaccess)

If using Apache, you can add this to `.htaccess`:

```apache
# Serve delete-account.html at /delete-account URL
RewriteEngine On
RewriteRule ^delete-account$ delete-account.html [L]
```

### Nginx

If using Nginx, add to server config:

```nginx
location = /delete-account {
    try_files /delete-account.html =404;
}
```

## Verification

After uploading, verify:

1. **Check URL is accessible:**
   ```bash
   curl -I https://www.wassle.ps/delete-account
   ```
   Should return: `HTTP/2 200` or `HTTP/1.1 200 OK`

2. **Test in browser:**
   - Open: https://www.wassle.ps/delete-account
   - Should show the delete account page (not empty)

3. **Test on mobile:**
   - Verify page is mobile-friendly
   - Check all links work

## Quick Test

After deployment, test with:

```bash
curl https://www.wassle.ps/delete-account
```

Should return HTML content, not empty page.

## File Content Preview

The `delete-account.html` file includes:
- ✅ Instructions on how to delete account from app
- ✅ OTP verification process
- ✅ Warning about permanent deletion
- ✅ Support contact information
- ✅ Mobile-friendly design

## Next Steps After Deployment

1. ✅ Verify URL is accessible
2. ✅ Test page loads correctly
3. ✅ Add URL to Google Play Console Data Safety section
4. ✅ Test on mobile devices

---

**Need Help?** Contact your web hosting provider for assistance with file uploads.

