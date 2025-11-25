# OTP API Documentation

## Overview

This document describes the new SMS-based OTP (One-Time Password) authentication system that replaces Firebase Phone Authentication. The system uses a local SMS provider to send and verify OTP codes via SMS.

## Backend Configuration

### Environment Variables

Add the following environment variables to your `.env` file:

```env
# HTC SMS Provider Configuration
SMS_API_URL=http://sms.htd.ps/API/SendSMS.aspx  # HTC SMS API endpoint (default)
SMS_API_KEY=1e6dacad8153ddc9b2b61bf94085f814   # Your HTC SMS API ID/Key
SMS_SENDER_ID=SenderName                        # Sender name (default: "SenderName")
```

**Note:** The SMS provider integration has been configured for HTC SMS Provider API. The implementation uses:
- **API Format**: GET request with query parameters
- **Endpoint**: `http://sms.htd.ps/API/SendSMS.aspx`
- **Parameters**: `id` (API key), `sender` (sender name), `to` (phone number), `msg` (message)
- **Phone Format**: `970XXXXXXXX` (country code + number, no + or leading 0)

### SMS Provider Integration

The SMS provider integration is located in `backend/src/utils/smsProvider.ts` and has been configured for HTC SMS Provider API. The implementation:

1. **Formats phone numbers** to HTC format (`970XXXXXXXX` - no + or leading 0)
2. **Sends GET requests** to HTC SMS API with query parameters
3. **Handles HTC error codes** (H001-H006 format) with user-friendly messages
4. **Verifies OTP** by comparing with stored OTP in database (HTC doesn't have verification endpoint)

## API Endpoints

### 1. Send Phone OTP

**Endpoint:** `POST /api/auth/send-phone-otp`

**Description:** Sends an OTP code to the specified phone number via SMS.

**Request Body:**
```json
{
  "phoneNumber": "+9700593202026"
}
```

**Response (Success - 200):**
```json
{
  "message": "OTP sent successfully",
  "phone": "+9700593202026"
}
```

**Response (Development Mode - includes OTP):**
```json
{
  "message": "OTP sent successfully",
  "phone": "+9700593202026",
  "otp": "123456"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid phone number format
- `500 Internal Server Error`: Failed to send SMS

**Notes:**
- Phone numbers are automatically normalized to the format `+9720XXXXXXXX`
- OTP codes are 6 digits and expire after 10 minutes
- In development mode, the OTP is included in the response for testing
- If SMS sending fails in development, the OTP is logged to console

---

### 2. Verify Phone OTP

**Endpoint:** `POST /api/auth/verify-phone-otp`

**Description:** Verifies the OTP code sent to the phone number and authenticates the user.

**Request Body:**
```json
{
  "phoneNumber": "+9700593202026",
  "otp": "123456"
}
```

**Response (Success - 200):**
```json
{
  "message": "Phone verified successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "name": "User 2026",
    "email": "970593202026@phone.local",
    "phone": "+9700593202026",
    "role": "customer",
    "vehicleType": null,
    "isAvailable": false,
    "profilePicture": null
  }
}
```

**Error Responses:**
- `400 Bad Request`: Invalid OTP, OTP expired, or no OTP found
- `404 Not Found`: No OTP request found for this phone number
- `500 Internal Server Error`: Server error during verification

**Notes:**
- The JWT token is automatically stored in the client's local storage
- Users are automatically created if they don't exist
- Phone numbers are normalized before verification
- OTP codes can only be used once and expire after 10 minutes

---

### 3. Send Order OTP (for Order Verification)

**Endpoint:** `POST /api/orders/send-otp`

**Description:** Sends an OTP code to verify phone number when creating an order.

**Request Body:**
```json
{
  "phone": "593202026",
  "countryCode": "+970"
}
```

**Response (Success - 200):**
```json
{
  "message": "OTP sent successfully",
  "phone": "+9700593202026"
}
```

**Notes:**
- This endpoint is used for order creation verification
- The OTP is sent via SMS using the same SMS provider

---

## Frontend Integration

### User App (Flutter)

The user app has been updated to use the new SMS-based OTP endpoints:

**Files Updated:**
- `user-app/lib/repositories/api_service.dart`: Added `sendPhoneOTP()` and `verifyPhoneOTP()` methods
- `user-app/lib/view_models/auth_view_model.dart`: Updated `sendOTP()` and `verifyOTP()` methods to use new endpoints

**Usage Example:**
```dart
// Send OTP
final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
final success = await authViewModel.sendOTP('+9700593202026');

// Verify OTP
final verified = await authViewModel.verifyOTP(
  phoneNumber: '+9700593202026',
  otp: '123456',
);
```

### Driver App

The driver app uses email-based OTP and doesn't require changes for phone authentication.

---

## Migration from Firebase

### What Changed

1. **Backend:**
   - New endpoints: `/api/auth/send-phone-otp` and `/api/auth/verify-phone-otp`
   - Old Firebase endpoints (`/api/auth/verify-firebase-token`, `/api/auth/phone-login`) are deprecated but still available for backward compatibility
   - SMS provider integration replaces Firebase Phone Authentication

2. **Frontend:**
   - Removed dependency on Firebase Auth SDK for phone authentication
   - Updated to use new backend endpoints directly
   - Simplified OTP flow (no Firebase verification ID needed)

### Backward Compatibility

- Firebase endpoints are still available but marked as deprecated
- Existing Firebase-based implementations will continue to work
- New implementations should use the SMS-based endpoints

---

## Security Considerations

1. **OTP Expiration**: OTP codes expire after 10 minutes
2. **Single Use**: OTP codes can only be used once
3. **Rate Limiting**: Consider implementing rate limiting to prevent abuse
4. **Phone Number Validation**: Phone numbers are normalized and validated before sending OTP
5. **Error Handling**: Sensitive error messages are not exposed to clients

---

## Testing

### Development Mode

In development mode (`NODE_ENV !== 'production'`):
- OTP codes are included in API responses
- OTP codes are logged to console if SMS sending fails
- This allows testing without actual SMS delivery

### Production Mode

In production mode:
- OTP codes are NOT included in API responses
- SMS sending failures return proper error messages
- All OTP codes must be delivered via SMS

---

## Troubleshooting

### SMS Not Sending

1. Check SMS provider configuration in `.env`:
   - Verify `SMS_API_URL` is correct
   - Verify `SMS_API_KEY` or `SMS_USERNAME`/`SMS_PASSWORD` are correct
   - Check SMS provider API documentation for correct format

2. Check SMS provider logs:
   - Review backend console logs for SMS sending errors
   - Verify SMS provider account has sufficient credits/quota

3. Test SMS provider connection:
   - Use a tool like Postman to test SMS provider API directly
   - Verify authentication credentials are working

### OTP Verification Failing

1. Check OTP expiration:
   - OTP codes expire after 10 minutes
   - Request a new OTP if expired

2. Verify phone number format:
   - Phone numbers are normalized automatically
   - Ensure phone number matches the one used to request OTP

3. Check backend logs:
   - Review error messages in backend console
   - Verify user exists in database with correct OTP code

---

## Next Steps

1. **Configure SMS Provider**: Update `backend/src/utils/smsProvider.ts` with your SMS provider's API details
2. **Test Integration**: Test sending and verifying OTP with real phone numbers
3. **Remove Firebase Dependencies** (Optional): Once fully migrated, you can remove Firebase Admin SDK if not used elsewhere
4. **Monitor Usage**: Track SMS usage and costs with your SMS provider
5. **Implement Rate Limiting**: Add rate limiting to prevent abuse of OTP endpoints

---

## Support

For issues or questions:
1. Check backend logs for detailed error messages
2. Verify SMS provider configuration
3. Review this documentation
4. Check SMS provider API documentation for specific requirements

