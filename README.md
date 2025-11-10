# Delivery Management System

A complete delivery management system with three components: Backend API, Admin Dashboard, User App (Customer), and Driver App.

## 🏗️ Project Structure

```
Awsaltak/
├── backend/              # Node.js + Express + TypeScript + MongoDB
├── admin-dashboard/      # React + TypeScript + Tailwind CSS
├── user-app/             # Flutter - Customer App
└── driver-app/           # Flutter - Driver App
```

## 🚀 Getting Started

> 📖 **For detailed step-by-step setup instructions, see [SETUP_GUIDE.md](./SETUP_GUIDE.md)**

### Quick Start

1. **Backend Setup**
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Edit .env with your configuration
   npm run dev
   ```

2. **Admin Dashboard Setup**
   ```bash
   cd admin-dashboard
   npm install
   npm run dev
   ```

3. **Flutter Apps Setup**
   ```bash
   cd user-app  # or driver-app
   flutter pub get
   flutter run
   ```

### Prerequisites

- Node.js (v18+)
- MongoDB
- Flutter SDK
- Resend API Key (for email OTP)

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file from `.env.example`:
```bash
cp .env.example .env
```

4. Update `.env` with your configuration:
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/delivery-system
JWT_SECRET=your-secret-key
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
```

5. Run the backend:
```bash
npm run dev
```

Backend will run on `http://localhost:5000`

### Admin Dashboard Setup

1. Navigate to admin-dashboard directory:
```bash
cd admin-dashboard
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```env
VITE_API_URL=http://localhost:5000/api
```

4. Run the dashboard:
```bash
npm run dev
```

Dashboard will run on `http://localhost:3000`

### User App (Flutter) Setup

1. Navigate to user-app directory:
```bash
cd user-app
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. R
```

4. No API keys needed - maps use OpenStreetMap (free)

5. Run the app:
```bash
flutter run
```

### Driver App (Flutter) Setup

1. Navigate to driver-app directory:
```bash
cd driver-app
```
ٍRR
2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Update `lib/services/api_service.dart` with your backend URL

4. No API keys needed - maps use OpenStreetMap (free)

5. Run the app:
```bash
flutter run
```

## 📱 Features

### User App (Customer)
- ✅ User registration and login with OTP verification
- ✅ Live map with current location
- ✅ Send Request (create delivery from current location)
- ✅ Receive Request (receive delivery to current location)
- ✅ Real-time order tracking
- ✅ Order history

### Driver App
- ✅ Driver registration and login
- ✅ Toggle availability (online/offline)
- ✅ View available orders sorted by distance
- ✅ Accept/reject orders
- ✅ Active order tracking with map
- ✅ Update order status (accepted → on_the_way → delivered)
- ✅ Order history

### Admin Dashboard
- ✅ Login and authentication
- ✅ Dashboard with statistics
- ✅ User management
- ✅ Driver management
- ✅ Order management
- ✅ Map view for active drivers and orders
- ✅ Settings

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/verify-otp` - Verify OTP
- `GET /api/auth/me` - Get current user

### Orders
- `POST /api/orders` - Create order
- `GET /api/orders` - Get user orders
- `GET /api/orders/available` - Get available orders (driver)
- `POST /api/orders/:orderId/accept` - Accept order
- `PATCH /api/orders/:orderId/status` - Update order status
- `GET /api/orders/:orderId` - Get order details

### Users
- `PATCH /api/users/location` - Update location
- `PATCH /api/users/availability` - Update availability
- `GET /api/users` - Get all users (admin)
- `GET /api/users/:userId` - Get user by ID

## 🗄️ Database Schema

### Users Collection
```javascript
{
  _id: ObjectId,
  name: String,
  email: String,
  password: String (hashed),
  role: "customer" | "driver" | "admin",
  location: { lat: Number, lng: Number },
  isAvailable: Boolean,
  phoneNumber: String,
  isEmailVerified: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

### Orders Collection
```javascript
{
  _id: ObjectId,
  customerId: ObjectId,
  driverId: ObjectId,
  type: "send" | "receive",
  pickupLocation: { lat: Number, lng: Number, address: String },
  dropoffLocation: { lat: Number, lng: Number, address: String },
  price: Number,
  status: "pending" | "accepted" | "on_the_way" | "delivered" | "cancelled",
  distance: Number,
  estimatedTime: Number,
  createdAt: Date,
  updatedAt: Date
}
```

## 🔌 Real-time Updates

The system uses Socket.io for real-time updates:
- New order notifications to drivers
- Order status updates
- Driver location updates
- Order acceptance notifications

## 📝 Notes

1. Make sure MongoDB is running before starting the backend
2. Configure email settings in `.env` for OTP functionality
3. No API keys needed - maps use OpenStreetMap (free)
4. For production, update API URLs in Flutter apps
5. Use HTTPS in production for security

## 🛠️ Technologies Used

- **Backend**: Node.js, Express, TypeScript, MongoDB, Socket.io
- **Admin Dashboard**: React, TypeScript, Tailwind CSS, Vite
- **Mobile Apps**: Flutter, Provider, Flutter Map (Leaflet), Geolocator
- **Authentication**: JWT, OTP (Email)
- **Real-time**: Socket.io

## 📄 License

This project is for educational purposes.
