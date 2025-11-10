# 🚀 Complete Setup Guide - Delivery Management System

Follow these steps to get your delivery system up and running.

## 📋 Prerequisites

1. **Node.js** (v18 or higher) - [Download](https://nodejs.org/)
2. **MongoDB** - [Download](https://www.mongodb.com/try/download/community) or use [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) (free tier)
3. **Flutter SDK** - [Install Flutter](https://flutter.dev/docs/get-started/install)
4. **Google Maps API Key** - [Get API Key](https://console.cloud.google.com/google/maps-apis)
5. **Resend Account** - [Sign up](https://resend.com/)

---

## 🔧 Step 1: Backend Setup

### 1.1 Install Dependencies
```bash
cd backend
npm install
```

### 1.2 Configure Environment Variables
Edit the `.env` file in the `backend` directory:

```env
PORT=5000
NODE_ENV=development

# Primary database (MongoDB Atlas or another remote instance)
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/delivery-system

# Optional: override the local fallback URI used in development. If omitted,
# the backend falls back to mongodb://127.0.0.1:27017/delivery-system.
MONGODB_LOCAL_URI=mongodb://127.0.0.1:27017/delivery-system

JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
OTP_SECRET=your-otp-secret-key

# Resend Configuration
RESEND_API_KEY=re_5mFnys1n_CihyRAZtmoRThZhbw3dUwZeR
RESEND_FROM_EMAIL=noreply@yourdomain.com
# For testing, use: onboarding@resend.dev

GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

**Generate secure secrets:**
```bash
# Generate JWT_SECRET
echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env

# Generate OTP_SECRET (if not already done)
echo "OTP_SECRET=$(openssl rand -hex 32)" >> .env
```

### 1.3 Start MongoDB
**Local MongoDB:**
```bash
# macOS (using Homebrew)
brew services start mongodb-community

# Or run manually
mongod
```

**Or use MongoDB Atlas:**
- Create a free account at [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
- Create a cluster
- Get your connection string
- Update `MONGODB_URI` in `.env`

### 1.4 Run the Backend
```bash
npm run dev
```

The backend should now be running on `http://localhost:5000`

---

## 📧 Step 2: Resend Email Setup

### 2.1 Create Resend Account
1. Go to [resend.com](https://resend.com/)
2. Sign up for a free account
3. Verify your email

### 2.2 Get Your API Key
1. Go to [Resend Dashboard](https://resend.com/api-keys)
2. Click "Create API Key"
3. Copy the API key (starts with `re_`)
4. Add it to your `.env` file: `RESEND_API_KEY=re_...`

### 2.3 Verify Domain (Optional - for production)
1. Go to [Resend Domains](https://resend.com/domains)
2. Click "Add Domain"
3. Follow the DNS verification steps
4. Update `RESEND_FROM_EMAIL` in `.env` with your verified domain

**For Testing:**
- You can use `onboarding@resend.dev` without domain verification
- Update `.env`: `RESEND_FROM_EMAIL=onboarding@resend.dev`

---

## 🗺️ Step 3: Google Maps API Setup

### 3.1 Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable billing (required for Maps API)

### 3.2 Enable Maps SDK
1. Go to [APIs & Services > Library](https://console.cloud.google.com/apis/library)
2. Enable these APIs:
   - **Maps JavaScript API** (for admin dashboard)
   - **Maps SDK for Android** (for Flutter apps)
   - **Maps SDK for iOS** (for Flutter apps)
   - **Geocoding API** (for address conversion)

### 3.3 Create API Key
1. Go to [APIs & Services > Credentials](https://console.cloud.google.com/apis/credentials)
2. Click "Create Credentials" > "API Key"
3. Copy the API key
4. (Recommended) Restrict the API key:
   - Click on the key to edit
   - Under "API restrictions", select "Restrict key"
   - Choose the Maps APIs you enabled
   - Under "Application restrictions", add your domains/apps

### 3.4 Add API Key to Projects
- **Backend**: Add to `.env`: `GOOGLE_MAPS_API_KEY=your-key`
- **Admin Dashboard**: Add to `.env`: `VITE_GOOGLE_MAPS_API_KEY=your-key`
- **Flutter Apps**: Add to `android/app/src/main/AndroidManifest.xml`

---

## 💻 Step 4: Admin Dashboard Setup

### 4.1 Install Dependencies
```bash
cd admin-dashboard
npm install
```

### 4.2 Configure Environment
Create `.env` file:
```env
VITE_API_URL=http://localhost:5000/api
VITE_GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

### 4.3 Run the Dashboard
```bash
npm run dev
```

The dashboard will be available at `http://localhost:3000`

### 4.4 Create Admin User
You'll need to create an admin user. You can either:
- **Option A**: Use MongoDB directly to update a user's role to "admin"
- **Option B**: Register via API and manually update in database:
  ```bash
  # Register a user
  curl -X POST http://localhost:5000/api/auth/register \
    -H "Content-Type: application/json" \
    -d '{"name":"Admin","email":"admin@example.com","password":"password123","role":"admin"}'
  
  # Then in MongoDB, update the user role to "admin"
  ```

---

## 📱 Step 5: Flutter User App Setup

### 5.1 Install Flutter Dependencies
```bash
cd user-app
flutter pub get
```

### 5.2 Configure API URL
Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:5000/api';
// For Android emulator, use: 'http://10.0.2.2:5000/api'
// For iOS simulator, use: 'http://localhost:5000/api'
// For physical device, use your computer's IP: 'http://192.168.1.X:5000/api'
```

### 5.3 Add Google Maps API Key
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

For iOS, edit `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 5.4 Run the App
```bash
# For Android
flutter run

# For iOS
flutter run -d ios
```

---

## 🚗 Step 6: Flutter Driver App Setup

### 6.1 Install Flutter Dependencies
```bash
cd driver-app
flutter pub get
```

### 6.2 Configure API URL
Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:5000/api';
// Same notes as User App above
```

### 6.3 Add Google Maps API Key
Same as User App (Step 5.3)

### 6.4 Run the App
```bash
flutter run
```

---

## ✅ Step 7: Testing the System

### 7.1 Test Backend
```bash
# Health check
curl http://localhost:5000/health

# Should return: {"status":"OK","message":"Server is running"}
```

### 7.2 Test Registration Flow
1. Open User App
2. Register a new account
3. Check your email for OTP (sent via Resend)
4. Verify OTP
5. Login

### 7.3 Test Order Flow
1. **User App**: Create a delivery request
2. **Driver App**: 
   - Login as driver
   - Toggle "Available" to ON
   - View available orders
   - Accept an order
3. **User App**: Track the order in real-time

### 7.4 Test Admin Dashboard
1. Login to admin dashboard
2. View statistics
3. Check users, drivers, and orders

---

## 🔍 Troubleshooting

### MongoDB Connection Issues
- Ensure MongoDB is running: `mongod` or `brew services start mongodb-community`
- Check connection string in `.env`
- For Atlas: Whitelist your IP address
- The backend now retries connections and falls back to `MONGODB_LOCAL_URI` (when `NODE_ENV !== 'production'`) if the primary URI fails. Verify both values if you still cannot connect.

### Resend Email Not Sending
- Verify API key is correct
- Check Resend dashboard for delivery status
- Use `onboarding@resend.dev` for testing
- Check spam folder

### Google Maps Not Loading
- Verify API key is correct
- Enable required APIs in Google Cloud Console
- Check API key restrictions
- For Android: Add API key to `AndroidManifest.xml`
- For iOS: Add API key to `AppDelegate.swift`

### Flutter App Can't Connect to Backend
- **Android Emulator**: Use `http://10.0.2.2:5000/api`
- **iOS Simulator**: Use `http://localhost:5000/api`
- **Physical Device**: Use your computer's IP address
- Ensure backend is running
- Check firewall settings

### Socket.io Not Working
- Ensure backend is running
- Check token is being sent correctly
- Verify Socket.io is initialized in both apps

---

## 📚 Additional Resources

- [Resend Documentation](https://resend.com/docs)
- [Google Maps Platform](https://developers.google.com/maps)
- [Flutter Documentation](https://flutter.dev/docs)
- [MongoDB Documentation](https://docs.mongodb.com/)

---

## 🎯 Quick Start Checklist

- [ ] Backend dependencies installed
- [ ] MongoDB running
- [ ] `.env` file configured with all keys
- [ ] Backend running on port 5000
- [ ] Resend API key configured
- [ ] Google Maps API key configured
- [ ] Admin dashboard running on port 3000
- [ ] User app dependencies installed
- [ ] Driver app dependencies installed
- [ ] Test registration flow
- [ ] Test order creation and acceptance

---

## 🚀 Production Deployment

### Backend (Render/Vercel/Railway)
1. Set environment variables in hosting platform
2. Update `MONGODB_URI` to production database
3. Update `RESEND_FROM_EMAIL` to verified domain
4. Update CORS settings for production domains

### Admin Dashboard (Vercel/Netlify)
1. Set environment variables
2. Update `VITE_API_URL` to production backend URL
3. Deploy

### Flutter Apps
1. Update API URLs in both apps
2. Build for production:
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release   # iOS
   ```
3. Upload to Play Store / App Store

---

**Happy coding! 🎉**
