# OTP Delivery Verification Guide

## ✅ Changes Implemented

### 1. **SMS Sending Restored**
- Re-enabled SMS sending via Vonage (removed WhatsApp to avoid error 1120)
- SMS is now the primary delivery method

### 2. **Comprehensive Logging Added**
The system now logs every step of the OTP delivery process:

#### Configuration Check
- ✅ API Key presence and partial value
- ✅ API Secret presence
- ✅ From Number configuration
- ✅ Sandbox mode status

#### Request Tracking
- Full request payload (phone, message, channel)
- API endpoint URL
- Authentication header (partial)
- Request timing

#### Response Tracking
- HTTP status code
- Response headers
- Full response body
- Response timing
- Message UUID (on success)

#### Error Tracking
- Error type and message
- Stack traces
- Response data (if available)
- Duration before error

### 3. **Error Handling Enhanced**
- Clear error messages with actionable guidance
- Specific handling for error 1120 (Invalid sender)
- Development mode fallback (returns OTP in response)

## 🔍 Verification Checklist

### Step 1: Check Environment Variables

Verify these are set in `backend/.env`:

```env
VONAGE_API_KEY=your_api_key_here
VONAGE_API_SECRET=your_api_secret_here
VONAGE_FROM_NUMBER=your_number_here  # Optional but recommended
# OR
VONAGE_SENDER_ID=YourAppName  # Alphanumeric sender ID
```

**To verify:**
```bash
cd backend
grep -E "VONAGE_" .env
```

### Step 2: Verify Vonage Dashboard Configuration

1. **Login to Vonage Dashboard**: https://dashboard.nexmo.com/
2. **Check API Credentials**:
   - Go to Settings → API Credentials
   - Verify API Key matches your `.env` file
   - Verify API Secret matches your `.env` file

3. **Check Phone Number** (if using VONAGE_FROM_NUMBER):
   - Go to Numbers → Your Numbers
   - Verify the number is active
   - Verify it's enabled for SMS
   - Note: For SMS, you can also use an alphanumeric sender ID

4. **Check Account Balance**:
   - Go to Account → Balance
   - Ensure you have sufficient credit

### Step 3: Test OTP Sending

1. **Restart your backend server** to load new logging:
   ```bash
   cd backend
   npm run dev
   ```

2. **Send a test OTP**:
   ```bash
   curl -X POST http://localhost:5001/api/orders/send-otp \
     -H "Content-Type: application/json" \
     -d '{"phone": "593202026", "countryCode": "+972"}'
   ```

3. **Check server logs** - You should see:
   ```
   🔵 ===== OTP SENDING PROCESS START =====
   📡 ===== SMS SERVICE CALLED =====
   🔍 ===== CONFIGURATION CHECK =====
   🌐 ===== VONAGE API REQUEST =====
   📤 ===== REQUEST PAYLOAD =====
   📥 ===== VONAGE API RESPONSE =====
   ✅ ===== SMS SENT SUCCESSFULLY =====
   ```

### Step 4: Analyze Logs

Look for these key indicators:

#### ✅ Success Indicators:
- Status Code: `202` (Accepted) or `200` (OK)
- Response contains `message_uuid`
- No error messages in logs

#### ❌ Failure Indicators:
- Status Code: `422` (Unprocessable Entity) - Usually means invalid sender
- Status Code: `401` (Unauthorized) - Invalid API credentials
- Status Code: `402` (Payment Required) - Insufficient credit
- Error message contains "Invalid sender" - Sender number/ID not configured
- Error message contains "authentication-failed" - Wrong API credentials

## 🐛 Common Issues & Solutions

### Issue 1: Error 1120 - Invalid Sender

**Symptoms:**
- Status Code: 422
- Error: "The `from` parameter is invalid"

**Solutions:**
1. **Use Alphanumeric Sender ID** (Recommended for SMS):
   ```env
   VONAGE_SENDER_ID=YourAppName
   ```
   Remove `VONAGE_FROM_NUMBER` if set

2. **Purchase a Virtual Number**:
   - Go to Vonage Dashboard → Numbers → Buy Numbers
   - Purchase a number for SMS
   - Set `VONAGE_FROM_NUMBER` to that number

3. **Verify Number Format**:
   - Must be in E.164 format: `+1234567890`
   - No spaces, dashes, or parentheses

### Issue 2: Authentication Failed

**Symptoms:**
- Status Code: 401
- Error: "authentication-failed"

**Solutions:**
1. Verify API Key and Secret in `.env` match Vonage Dashboard
2. Check for extra spaces in environment variables
3. Restart server after changing `.env`

### Issue 3: Insufficient Credit

**Symptoms:**
- Status Code: 402
- Error: "insufficient-credit"

**Solutions:**
1. Go to Vonage Dashboard → Account → Balance
2. Top up your account
3. Retry sending

### Issue 4: Messages Not Being Delivered

**Symptoms:**
- API returns success (202/200)
- User doesn't receive SMS

**Possible Causes:**
1. **Carrier Filtering**: Some carriers block messages from unverified numbers
   - Solution: Use a verified virtual number or alphanumeric sender ID

2. **Phone Number Format**: Recipient number might be incorrect
   - Solution: Verify phone number is in E.164 format

3. **Country Restrictions**: Some countries have SMS restrictions
   - Solution: Check Vonage's country coverage

4. **Spam Filtering**: Message might be filtered as spam
   - Solution: Use a verified sender ID

## 📊 Log Analysis Guide

### Successful Delivery Log Example:
```
🔵 ===== OTP SENDING PROCESS START =====
📱 Phone: +972593202026
🔑 OTP Code: 123456
📡 ===== SMS SERVICE CALLED =====
🔍 ===== CONFIGURATION CHECK =====
🔑 API Key Present: ✅ YES (a15e...)
🔐 API Secret Present: ✅ YES
📞 From Number: YourAppName
🌐 ===== VONAGE API REQUEST =====
🔗 Endpoint: https://api.nexmo.com/v1/messages
📤 ===== REQUEST PAYLOAD =====
{
  "message_type": "text",
  "to": "+972593202026",
  "from": "YourAppName",
  "channel": "sms"
}
📥 ===== VONAGE API RESPONSE =====
📊 Status Code: 202 Accepted
📦 Response Body: {
  "message_uuid": "abc-123-def"
}
✅ ===== SMS SENT SUCCESSFULLY =====
🆔 Message UUID: abc-123-def
```

### Failed Delivery Log Example:
```
❌ ===== VONAGE API ERROR =====
📊 Status Code: 422 Unprocessable Entity
📦 Response Body: {
  "title": "Invalid sender",
  "detail": "The `from` parameter is invalid."
}
❌ Error Message: Vonage API error (https://developer.vonage.com/api-errors/messages#1120): The `from` parameter is invalid.
```

## 🔧 Next Steps

1. **Review the logs** after sending a test OTP
2. **Check the response status code** - should be 202 or 200
3. **Verify message_uuid** is present in successful responses
4. **Check Vonage Dashboard** → Messages → Activity to see delivery status
5. **If still not working**, share the complete logs for analysis

## 📞 Support Resources

- **Vonage Dashboard**: https://dashboard.nexmo.com/
- **Vonage API Documentation**: https://developer.vonage.com/en/api/messages-olympus
- **Vonage Support**: https://help.nexmo.com/
- **API Status**: https://status.nexmo.com/

## 🎯 Quick Test Command

```bash
# Test OTP sending with full logging
curl -X POST http://localhost:5001/api/orders/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "593202026", "countryCode": "+972"}' \
  -v
```

Then check your server logs for the detailed output.

