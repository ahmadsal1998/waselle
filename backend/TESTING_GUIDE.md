# SMS OTP Testing Guide

## Test Results

**Phone Number Tested:** `+9720593202026`

**Result:** ❌ Error - `H008|Sender Not Approved`

## Issue

The sender ID "SenderName" is not approved in the HTC SMS system. You need to use an approved sender ID.

## Solutions

### Option 1: Use an Approved Sender ID

1. Contact your HTC SMS provider to get a list of approved sender IDs
2. Update your `.env` file with an approved sender ID:

```env
SMS_SENDER_ID=YourApprovedSenderID
```

### Option 2: Request Sender ID Approval

1. Contact HTC SMS provider support
2. Request approval for your desired sender ID
3. Once approved, update your `.env` file

### Option 3: Test with Default Approved Sender

Some SMS providers have a default approved sender. Try:
- Your company name
- A short code provided by HTC
- A numeric sender ID (if supported)

## Testing the SMS OTP

### Method 1: Using the Test Script

```bash
cd backend
npm run test:sms
```

### Method 2: Using the API Endpoint

```bash
curl -X POST http://localhost:5001/api/auth/send-phone-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+9720593202026"}'
```

### Method 3: Using Postman/Thunder Client

1. **Endpoint:** `POST http://localhost:5001/api/auth/send-phone-otp`
2. **Headers:** `Content-Type: application/json`
3. **Body:**
```json
{
  "phoneNumber": "+9720593202026"
}
```

## Expected Behavior

### Success Response
```json
{
  "message": "OTP sent successfully",
  "phone": "+970593202026"
}
```

### Error Response (Current Issue)
```json
{
  "message": "SMS API Error: Sender ID not approved. Please use an approved sender ID or contact HTC SMS provider to approve your sender ID."
}
```

## Phone Number Format

The system automatically formats phone numbers for HTC API:
- Input: `+9720593202026`
- Formatted for API: `970593202026` (removes `+` and leading `0`)

## Next Steps

1. ✅ **Get Approved Sender ID** - Contact HTC SMS provider
2. ✅ **Update .env** - Set `SMS_SENDER_ID` to approved value
3. ✅ **Test Again** - Run `npm run test:sms`
4. ✅ **Verify SMS Delivery** - Check phone for OTP message

## Troubleshooting

### Error: H008|Sender Not Approved
- **Solution:** Use an approved sender ID or request approval

### Error: H006|Invalid DESTINATION Parameter
- **Solution:** Check phone number format (should be valid international format)

### Error: H001/H002|Authentication Failed
- **Solution:** Verify `SMS_API_KEY` in `.env` file

### Error: H005|Insufficient Credits
- **Solution:** Add credits to your HTC SMS account

### Error: Unable to reach SMS service
- **Solution:** Check internet connection and `SMS_API_URL` configuration

## Configuration Checklist

- [ ] `SMS_API_URL` is set correctly
- [ ] `SMS_API_KEY` is valid
- [ ] `SMS_SENDER_ID` is approved by HTC SMS provider
- [ ] Backend server is running
- [ ] Internet connection is active

