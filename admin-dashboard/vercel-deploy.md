# Vercel Deployment Guide - Cache Clearing

## If Vercel Shows Old Version After Deploy

### Method 1: Clear Vercel Cache via Dashboard
1. Go to your Vercel project dashboard
2. Navigate to **Settings** → **General**
3. Scroll down to **Deployments**
4. Click **"Clear Build Cache"** or **"Redeploy"**
5. Select **"Redeploy"** on the latest deployment

### Method 2: Force Redeploy via CLI
```bash
# Install Vercel CLI if not installed
npm i -g vercel

# Login to Vercel
vercel login

# Force redeploy with no cache
vercel --prod --force
```

### Method 3: Clear Cache via Vercel API
```bash
# Get your Vercel token from: https://vercel.com/account/tokens
# Then run:
curl -X DELETE "https://api.vercel.com/v1/deployments/[DEPLOYMENT_ID]" \
  -H "Authorization: Bearer YOUR_VERCEL_TOKEN"
```

### Method 4: Update vercel.json (Already Done)
The `vercel.json` file has been updated with:
- Cache-Control headers to prevent caching
- Proper build configuration
- Asset caching with immutable hashes

### Method 5: Add Build ID to Force New Build
Add this to your `package.json` scripts:
```json
"build": "tsc && vite build && echo $(date +%s) > dist/.build-id"
```

### Method 6: Check Vercel Project Settings
1. Go to **Project Settings** → **General**
2. Ensure **"Build Command"** is: `npm run build`
3. Ensure **"Output Directory"** is: `dist`
4. Ensure **"Install Command"** is: `npm install`
5. Check **"Root Directory"** is set correctly (should be `admin-dashboard` if monorepo)

### Method 7: Verify Branch Connection
1. Go to **Project Settings** → **Git**
2. Ensure the correct branch (`main`) is connected
3. Verify the latest commit is being deployed
4. Check deployment logs for any errors

### Method 8: Hard Refresh Browser
After deployment:
- **Chrome/Edge**: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
- **Firefox**: `Ctrl+F5` (Windows) or `Cmd+Shift+R` (Mac)
- **Safari**: `Cmd+Option+R`

### Troubleshooting Steps
1. Check Vercel build logs for errors
2. Verify the build completes successfully
3. Check that the correct files are in the `dist/` folder
4. Verify environment variables are set correctly
5. Check that the API URL is correct in production

### Quick Fix Command
```bash
# Force a new deployment by making a small change
echo "// Build: $(date)" >> src/main.tsx
git add .
git commit -m "Force redeploy - clear cache"
git push origin main
```

