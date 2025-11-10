# 👤 Create Admin User - Step by Step Guide

Two methods to create an admin user for the Admin Dashboard.

## Method 1: Register via API + Update Role in MongoDB (Recommended)

### Step 1: Register a User via API

Use curl, Postman, or any HTTP client to register a new user:

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin User",
    "email": "admin@example.com",
    "password": "Admin123456",
    "phoneNumber": "+1234567890",
    "role": "admin"
  }'
```

**Note:** Even if you send `role: "admin"`, the backend might set it to "customer" by default. That's okay - we'll update it in MongoDB.

**Expected Response:**
```json
{
  "message": "Registration successful. Please verify your email with OTP.",
  "userId": "..."
}
```

### Step 2: Verify Email with OTP

Check your email for the OTP code, then verify:

```bash
curl -X POST http://localhost:5000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "otp": "123456"
  }'
```

**Expected Response:**
```json
{
  "message": "Email verified successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "name": "Admin User",
    "email": "admin@example.com",
    "role": "customer"
  }
}
```

### Step 3: Update Role to Admin in MongoDB

#### Option A: Using MongoDB Shell (mongosh)

```bash
# Connect to MongoDB
mongosh

# Or if using MongoDB Atlas connection string
mongosh "mongodb://localhost:27017/delivery-system"

# Switch to your database
use delivery-system

# Update the user role to admin
db.users.updateOne(
  { email: "admin@example.com" },
  { $set: { role: "admin" } }
)

# Verify the update
db.users.findOne({ email: "admin@example.com" })
```

#### Option B: Using MongoDB Compass (GUI)

1. Open MongoDB Compass
2. Connect to your database (`mongodb://localhost:27017` or your Atlas connection)
3. Navigate to `delivery-system` database → `users` collection
4. Find the user with email `admin@example.com`
5. Click on the document to edit
6. Change `role` from `"customer"` to `"admin"`
7. Click "Update"

#### Option C: Using MongoDB Atlas Web Interface

1. Log in to [MongoDB Atlas](https://cloud.mongodb.com/)
2. Go to your cluster → "Browse Collections"
3. Select `delivery-system` database → `users` collection
4. Find the user document
5. Click "Edit Document"
6. Change `role: "customer"` to `role: "admin"`
7. Click "Update"

### Step 4: Verify Admin Access

Try logging in to the Admin Dashboard:

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "Admin123456"
  }'
```

**Expected Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "name": "Admin User",
    "email": "admin@example.com",
    "role": "admin"
  }
}
```

Now you can use this token in the Admin Dashboard!

---

## Method 2: Direct MongoDB Insert (Quick but bypasses validation)

If you want to create an admin user directly in MongoDB without going through the API:

### Step 1: Connect to MongoDB

```bash
mongosh "mongodb://localhost:27017/delivery-system"
```

### Step 2: Create Admin User Directly

```javascript
use delivery-system

db.users.insertOne({
  name: "Admin User",
  email: "admin@example.com",
  password: "$2a$10$YourHashedPasswordHere", // You need to hash the password
  role: "admin",
  isEmailVerified: true,
  isAvailable: false,
  createdAt: new Date(),
  updatedAt: new Date()
})
```

**⚠️ Important:** You need to hash the password using bcrypt. Use this Node.js script:

```javascript
const bcrypt = require('bcryptjs');
const hashedPassword = bcrypt.hashSync('Admin123456', 10);
console.log(hashedPassword);
```

Then use the hashed password in the insertOne command.

---

## Method 3: Using a Script (Easiest)

Create a file `create-admin.js`:

```javascript
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const UserSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
  role: String,
  isEmailVerified: Boolean,
  createdAt: Date,
  updatedAt: Date
});

const User = mongoose.model('User', UserSchema);

async function createAdmin() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const hashedPassword = await bcrypt.hash('Admin123456', 10);

    const admin = await User.findOneAndUpdate(
      { email: 'admin@example.com' },
      {
        name: 'Admin User',
        email: 'admin@example.com',
        password: hashedPassword,
        role: 'admin',
        isEmailVerified: true,
        isAvailable: false,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      { upsert: true, new: true }
    );

    console.log('✅ Admin user created:', admin);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createAdmin();
```

Run it:
```bash
cd backend
node create-admin.js
```

---

## 🔐 Quick Reference

### API Endpoints Used

**Register:**
```bash
POST http://localhost:5000/api/auth/register
Body: {
  "name": "Admin User",
  "email": "admin@example.com",
  "password": "Admin123456",
  "role": "admin"
}
```

**Verify OTP:**
```bash
POST http://localhost:5000/api/auth/verify-otp
Body: {
  "email": "admin@example.com",
  "otp": "123456"
}
```

**Login:**
```bash
POST http://localhost:5000/api/auth/login
Body: {
  "email": "admin@example.com",
  "password": "Admin123456"
}
```

### MongoDB Update Command

```javascript
db.users.updateOne(
  { email: "admin@example.com" },
  { $set: { role: "admin" } }
)
```

---

## ✅ Verification Checklist

- [ ] User registered successfully
- [ ] Email verified (OTP confirmed)
- [ ] Role updated to "admin" in MongoDB
- [ ] Can login with admin credentials
- [ ] Can access Admin Dashboard
- [ ] Can see all users, drivers, and orders

---

**Need help?** Check the backend logs for any errors during registration or verification.
