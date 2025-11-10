# 📊 Admin Dashboard Setup Guide

Complete setup instructions for the Delivery System Admin Dashboard.

## ✅ Prerequisites

- Node.js (v18 or higher)
- Backend API running on `http://localhost:5000` (or update `.env`)

## 🚀 Quick Setup

### Step 1: Install Dependencies

```bash
cd admin-dashboard
npm install
```

### Step 2: Configure Environment

Create a `.env` file in the `admin-dashboard` directory:

```env
VITE_API_URL=http://localhost:5000/api
```

**For production:**
```env
VITE_API_URL=https://your-backend-url.com/api
```

### Step 3: Start Development Server

```bash
npm run dev
```

The dashboard will be available at: **http://localhost:3000**

## 📦 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## 🔐 Login

1. Navigate to http://localhost:3000
2. You'll be redirected to the login page
3. Login with admin credentials

**Note:** You need to create an admin user first. Options:
- Use MongoDB to manually update a user's role to "admin"
- Register via API with role "admin" and verify in database

## 🎯 Features

- ✅ **Dashboard Overview** - Statistics and charts
- ✅ **Users Management** - View and manage customers
- ✅ **Drivers Management** - View and manage drivers
- ✅ **Orders Management** - View all orders and their status
- ✅ **Map View** - Interactive map with Leaflet/OpenStreetMap
- ✅ **Settings** - System configuration

## 🗺️ Map Integration

The dashboard uses **Leaflet + OpenStreetMap** - no API keys required!

- Free and open-source
- No configuration needed
- Works immediately

## 🏗️ Build for Production

```bash
npm run build
```

The production build will be in the `dist/` directory.

### Deploy to Vercel

1. Push your code to GitHub
2. Import project in Vercel
3. Add environment variable:
   - `VITE_API_URL` = Your production backend URL
4. Deploy

### Deploy to Netlify

1. Push your code to GitHub
2. Import project in Netlify
3. Build command: `npm run build`
4. Publish directory: `dist`
5. Add environment variable:
   - `VITE_API_URL` = Your production backend URL
6. Deploy

## 🐛 Troubleshooting

### Cannot connect to backend
- Ensure backend is running on port 5000
- Check `VITE_API_URL` in `.env` file
- Verify CORS is enabled in backend

### Map not loading
- Check internet connection (OSM tiles load from servers)
- Verify Leaflet CSS is imported (should be automatic)
- Check browser console for errors

### Login not working
- Verify backend authentication endpoints are working
- Check browser console for errors
- Ensure user has "admin" role in database

### Build errors
- Run `npm install` to ensure all dependencies are installed
- Check TypeScript errors: `npm run build`
- Verify all environment variables are set

## 📚 Tech Stack

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Tailwind CSS** - Styling
- **React Router** - Navigation
- **Axios** - HTTP client
- **Recharts** - Charts and graphs
- **React Leaflet** - Maps (Leaflet + OpenStreetMap)
- **Socket.io Client** - Real-time updates

## 🔄 Real-time Updates

The dashboard uses Socket.io for real-time updates:
- Order status changes
- Driver location updates
- New order notifications

## 📝 Notes

- The dashboard requires the backend API to be running
- Admin users must have `role: "admin"` in the database
- All API calls are authenticated using JWT tokens
- Tokens are stored in localStorage

---

**Ready to go!** 🎉
