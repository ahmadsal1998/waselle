# ZegoCloud Voice Call Setup Guide

This guide explains how to configure the secure voice call feature between drivers and users using ZegoCloud with server-side token generation.

## Prerequisites

1. Create a ZegoCloud account at https://www.zegocloud.com/
2. Create a new project in the ZegoCloud console
3. Get your App ID and Server Secret from the project settings

## Security Implementation

This implementation uses **server-side token generation** for maximum security:
- ✅ App Sign is **NOT** stored in Flutter apps
- ✅ Tokens are generated on the backend server
- ✅ Tokens expire after 2 hours
- ✅ Only authenticated users can request tokens

## Configuration Steps

### 1. Backend Configuration (REQUIRED)

Add the following environment variables to your `.env` file in the `backend` directory:

```env
ZEGO_APP_ID=your_app_id_here
ZEGO_SERVER_SECRET=your_server_secret_here
```

**Important:** These credentials must be kept secure and never exposed to client-side code.

### 2. Backend Token Endpoint

The backend provides a secure token generation endpoint:

**Endpoint:** `POST /api/zego/token`

**Request Body:**
```json
{
  "userId": "user_id_here",
  "userName": "User Name",
  "roomId": "order_orderId_driverId_userId"
}
```

**Response:**
```json
{
  "token": "generated_token_here",
  "expireTime": 1234567890,
  "appID": 1234567890,
  "roomID": "order_orderId_driverId_userId",
  "userID": "user_id_here"
}
```

**Authentication:** Requires valid JWT token in Authorization header

### 3. Flutter Apps Configuration

**No configuration needed!** The Flutter apps automatically:
- Fetch tokens from the backend before starting calls
- Use tokens instead of App Sign
- Handle all authentication automatically

The apps are already configured to use the secure token-based approach.

## How It Works

1. **Room ID Generation**: Each call uses a unique room ID format:
   - Format: `order_{orderId}_{driverId}_{userId}`
   - Example: `order_507f1f77bcf86cd799439011_507f191e810c19729de860ea_507f1f77bcf86cd799439012`
   - This ensures only the assigned driver and customer can join the same room

2. **Secure Call Flow**:
   - User or Driver presses the "Call" button in the order tracking/details screen
   - App checks microphone permission
   - If permission granted, app requests a token from backend (`/api/zego/token`)
   - Backend validates user authentication and generates a secure token
   - Token is returned to the Flutter app
   - App uses the token to initialize ZegoUIKitPrebuiltCall
   - Full-screen voice call interface opens
   - Both parties join the same room using the secure token

3. **Token Security**:
   - Tokens are generated server-side using App ID + Server Secret
   - Tokens expire after 2 hours
   - Each token is unique to the user and room
   - Tokens cannot be reused or modified by clients

4. **Permissions**:
   - **Android**: `RECORD_AUDIO` permission is declared in `AndroidManifest.xml`
   - **iOS**: `NSMicrophoneUsageDescription` is added to `Info.plist`
   - Runtime permission requests are handled automatically

## Features

- ✅ Voice-only calls (no video)
- ✅ Full-screen call interface
- ✅ Works on iOS and Android
- ✅ Works on emulators (if microphone permission is granted)
- ✅ Automatic permission handling
- ✅ Room access restricted to order participants

## Testing

1. **Configure Backend:**
   - Add `ZEGO_APP_ID` and `ZEGO_SERVER_SECRET` to backend `.env` file
   - Restart the backend server

2. **Test the Flow:**
   - Create an order and have a driver accept it
   - Both parties should see a "Call" button in their order tracking/details screen
   - Press the button to start a voice call
   - App will automatically fetch token from backend
   - Grant microphone permission when prompted
   - The call should connect automatically

## Troubleshooting

### Call not connecting
- Verify `ZEGO_APP_ID` and `ZEGO_SERVER_SECRET` are correctly set in backend `.env`
- Check backend logs for token generation errors
- Verify backend is running and accessible
- Check network connectivity
- Ensure microphone permission is granted
- Verify user is authenticated (has valid JWT token)

### Token generation fails
- Check backend `.env` file has correct credentials
- Verify backend endpoint `/api/zego/token` is accessible
- Check backend logs for detailed error messages
- Ensure user is authenticated (JWT token in request header)

### Permission denied
- On Android: Go to Settings > Apps > [App Name] > Permissions > Microphone
- On iOS: Go to Settings > [App Name] > Microphone

### Backend endpoint not found
- Verify backend routes are properly configured
- Check that `/api/zego/token` route is registered in `server.ts`
- Ensure backend server is running

## Security Notes

✅ **Secure Implementation:**
- App Sign is **never** stored in Flutter apps
- All tokens are generated server-side
- Tokens expire after 2 hours
- Only authenticated users can request tokens
- Room IDs include order, driver, and user IDs for access control

⚠️ **Important:**
- Keep `ZEGO_SERVER_SECRET` secure and never commit it to version control
- Use environment variables for all sensitive credentials
- Tokens are single-use and expire automatically
- Backend validates user authentication before generating tokens

