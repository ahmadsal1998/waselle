# App Review Information for Apple App Store

## 📱 App Overview

**Awsaltak** is a delivery service application that connects customers with delivery drivers. The app allows users to:

- Place delivery orders with pickup and drop-off locations
- Track delivery drivers in real-time on an interactive map
- View order history and status updates
- Save multiple delivery addresses for quick access
- Receive real-time notifications about order status

The app supports both English and Arabic languages with full RTL (Right-to-Left) support for Arabic users.

---

## 🔑 How to Access the App (For Apple Reviewers)

**Review Mode is automatically active on TestFlight builds.**

When you install the app from TestFlight, Review Mode activates automatically. This means:

✅ **No login required** - A test user account is automatically authenticated  
✅ **Mock orders preloaded** - Sample orders are available for testing  
✅ **Test drivers visible** - Mock delivery drivers appear on the map  
✅ **Default location set** - The app starts at Ramallah center (Palestine) for testing  

**You can immediately start testing all features without any setup or registration.**

---

## 👤 How Registration Works (For Normal Users)

In the production version of the app, users follow this registration flow:

### Step 1: Account Creation
- Users sign up with their email address and phone number
- Password is required for account security
- Phone number verification via OTP (One-Time Password) may be required

### Step 2: Address Management
- After registration, users can save multiple delivery addresses
- Addresses can be added, edited, or deleted from the profile screen
- Saved addresses appear when placing new orders

### Step 3: Placing Orders
- Users select a saved address or enter a new delivery address
- Pickup location is automatically detected or manually entered
- Users can view estimated delivery time and cost
- Order is submitted and assigned to an available driver

### Step 4: Real-Time Tracking
- Once an order is placed, users can track the assigned driver on the map
- Real-time location updates show driver movement
- Order status updates (e.g., "Driver on the way", "Order delivered") are displayed
- Push notifications keep users informed of status changes

### Step 5: Order History
- All past orders are saved in the order history screen
- Users can view details of previous orders
- Order status, dates, and delivery information are preserved

---

## 🧪 How Review Mode Works

**Review Mode** is a special testing mode designed specifically for Apple App Store reviewers. It allows full testing of all app features without requiring:

- ❌ A separate driver app
- ❌ Real user accounts or login credentials
- ❌ Active delivery drivers
- ❌ Real-time backend services

### What Review Mode Provides:

1. **Automatic Authentication**
   - Test user account is automatically logged in
   - No login screen appears in Review Mode

2. **Preloaded Mock Data**
   - 3 sample orders are available in order history
   - Mock drivers are visible on the map
   - Test addresses are pre-configured

3. **Full Feature Access**
   - All screens and features are accessible
   - Order placement flow can be tested
   - Real-time tracking simulation works
   - Order history displays sample data

4. **Automatic Activation**
   - Review Mode activates automatically when the app runs from TestFlight
   - No manual configuration or settings changes needed
   - Works seamlessly for reviewers

### Important Security Note:

⚠️ **Review Mode is ONLY active in TestFlight builds.**  
✅ When the app is released to the App Store, Review Mode is automatically disabled  
✅ Regular users will see the normal login and registration flow  
✅ No test data or mock drivers will appear in production  

---

## 📝 Special Notes for Apple Reviewers

### ✅ What You Can Test:

1. **Order Placement**
   - Navigate to the home screen
   - Fill out the delivery request form
   - Select or enter pickup and delivery addresses
   - Submit an order (mock order will be created)

2. **Real-Time Tracking**
   - View the map with test drivers
   - See driver locations update in real-time
   - Track order status changes

3. **Order History**
   - View the 3 preloaded sample orders
   - Check order details and status
   - See order information and timestamps

4. **Profile & Settings**
   - Access saved addresses (test addresses available)
   - Change language (English/Arabic)
   - View app settings
   - Access Privacy Policy and Terms of Service links

5. **Navigation & UI**
   - Test tab navigation (Home, Orders, Profile)
   - Verify Arabic RTL support
   - Check all interactive elements

### 🚫 What You Don't Need:

- ❌ **No separate driver app required** - All testing can be done in this app
- ❌ **No login credentials needed** - Auto-authenticated in Review Mode
- ❌ **No backend setup** - Mock data is preloaded
- ❌ **No special configuration** - Everything works automatically

### 🎯 Key Testing Points:

1. **Functionality**: All features work correctly with mock data
2. **User Experience**: Navigation is smooth and intuitive
3. **Localization**: Both English and Arabic work properly
4. **Legal Compliance**: Privacy Policy and Terms of Service are accessible
5. **Error Handling**: App handles edge cases gracefully

---

## 🔍 Testing Checklist for Reviewers

To ensure comprehensive testing, please verify:

- [ ] App launches successfully without login screen (Review Mode active)
- [ ] Home screen displays correctly with map
- [ ] Can place a new delivery order
- [ ] Order history shows 3 sample orders
- [ ] Can view order details
- [ ] Real-time tracking shows driver on map
- [ ] Profile screen is accessible
- [ ] Language switching works (English ↔ Arabic)
- [ ] Privacy Policy link opens correctly
- [ ] Terms of Service link opens correctly
- [ ] All navigation flows work smoothly
- [ ] No crashes or errors occur

---

## 📞 Support Information

If you encounter any issues during review:

- **App Name**: Awsaltak
- **Bundle ID**: com.wassle.userapp
- **Version**: 1.0.1+6
- **Review Mode**: Automatically active in TestFlight builds

All features should work seamlessly in Review Mode. If you experience any problems, please note them in your review feedback.

---

## ✅ Summary

**For Apple Reviewers:**
- Install the app from TestFlight
- Review Mode activates automatically
- Test all features with preloaded mock data
- No login or setup required
- No separate driver app needed

**For Production Users:**
- Normal registration and login flow
- Real orders with real drivers
- Full backend integration
- Review Mode is automatically disabled

---

**Thank you for reviewing our app!** 🚀


