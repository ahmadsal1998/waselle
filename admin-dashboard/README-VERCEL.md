# Vercel Deployment - Cache Issues Fix

## Problem
Vercel showing old version after deployment due to caching.

## Solution Applied

### 1. Updated `vercel.json`
- Added cache-control headers to prevent HTML caching
- Configured proper build settings
- Set up asset caching with immutable hashes

### 2. Updated `vite.config.ts`
- Enabled manifest generation for cache busting
- Added hash-based filenames for all assets
- Enabled `emptyOutDir` to clear old files on build

### 3. Updated `index.html`
- Added cache-control meta tags
- Prevents browser from caching the HTML

## How to Force Fresh Deployment

### Option 1: Via Vercel Dashboard (Recommended)
1. Go to https://vercel.com/dashboard
2. Select your project
3. Go to **Deployments** tab
4. Click **"..."** menu on latest deployment
5. Select **"Redeploy"**
6. Check **"Use existing Build Cache"** = **OFF**
7. Click **"Redeploy"**

### Option 2: Via Git Push
```bash
# Make a small change to force rebuild
cd admin-dashboard
echo "// Build timestamp: $(date)" >> src/main.tsx
git add .
git commit -m "Force redeploy - clear cache"
git push origin main
```

### Option 3: Via Vercel CLI
```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy without cache
vercel --prod --force
```

### Option 4: Clear Build Cache
1. Go to Vercel Dashboard → Your Project
2. Settings → General
3. Scroll to "Build & Development Settings"
4. Click "Clear Build Cache"
5. Redeploy

## Verify Deployment

After deployment, check:
1. Open browser DevTools (F12)
2. Go to Network tab
3. Check "Disable cache" checkbox
4. Reload page (Ctrl+Shift+R or Cmd+Shift+R)
5. Verify new assets are loaded (check file names/hashes)

## Build Output

The build should output to `dist/` folder with:
- `index.html` (with cache-control headers)
- `assets/[name].[hash].js` (hashed filenames)
- `assets/[name].[hash].css` (hashed filenames)

## Troubleshooting

If still seeing old version:

1. **Check Build Logs**
   - Go to Vercel Dashboard → Deployments
   - Click on latest deployment
   - Check "Build Logs" for errors

2. **Verify Branch**
   - Settings → Git
   - Ensure correct branch is connected
   - Check latest commit hash matches GitHub

3. **Clear Browser Cache**
   - Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
   - Or use incognito/private window

4. **Check Environment Variables**
   - Settings → Environment Variables
   - Ensure `VITE_API_URL` is set correctly

5. **Verify Build Command**
   - Settings → General
   - Build Command: `npm run build`
   - Output Directory: `dist`
   - Install Command: `npm install`

## Configuration Files

- `vercel.json` - Vercel deployment configuration
- `vite.config.ts` - Vite build configuration with cache busting
- `index.html` - HTML with cache-control meta tags
- `.vercelignore` - Files to ignore during deployment

