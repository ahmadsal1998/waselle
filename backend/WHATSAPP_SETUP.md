# WhatsApp OTP Setup Guide

This guide explains how to configure WhatsApp OTP delivery using Meta WhatsApp Cloud API.

## Meta WhatsApp Cloud API Setup

### Prerequisites

1. A Meta (Facebook) Developer Account
2. A WhatsApp Business Account
3. A verified phone number for sending messages

### Step 1: Create a Meta App

1. Go to [Meta for Developers](https://developers.facebook.com/)
2. Create a new app or use an existing one
3. Add the "WhatsApp" product to your app

### Step 2: Get Your Credentials

You'll need the following from your Meta App:

1. **Access Token** (`WHATSAPP_ACCESS_TOKEN`):
   - Go to WhatsApp > API Setup in your Meta App dashboard
   - Copy the temporary access token (for testing) or generate a permanent one
   - For production, use a System User token with appropriate permissions

2. **Phone Number ID** (`WHATSAPP_PHONE_NUMBER_ID`):
   - Found in WhatsApp > API Setup
   - This is the ID of the phone number you'll use to send messages

3. **WhatsApp Business Account ID** (`WHATSAPP_BUSINESS_ACCOUNT_ID`) - Optional:
   - Found in your WhatsApp Business Account settings

4. **API Version** (`WHATSAPP_API_VERSION`) - Optional:
   - Default is `v21.0`
   - Check the latest version at [Meta's API Documentation](https://developers.facebook.com/docs/whatsapp/cloud-api)

### Step 3: Configure Environment Variables

Add the following to your `.env` file in the `backend` directory:

```env
# Meta WhatsApp Cloud API Configuration
WHATSAPP_ACCESS_TOKEN=your_access_token_here
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id_here
WHATSAPP_API_VERSION=v21.0
WHATSAPP_BUSINESS_ACCOUNT_ID=your_waba_id_here  # Optional
```

**Alternative variable names (also supported):**
```env
META_WHATSAPP_ACCESS_TOKEN=your_access_token_here
META_WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id_here
META_WHATSAPP_API_VERSION=v21.0
META_WHATSAPP_WABA_ID=your_waba_id_here  # Optional
```

### Step 4: Add Test Numbers (Development Mode)

In development mode, you can only send messages to verified test numbers:

1. Go to your Meta App dashboard
2. Navigate to WhatsApp > API Setup
3. Scroll down to "To" field
4. Click "Manage phone number list"
5. Add recipient phone numbers (in international format without +, e.g., `970501234567`)
6. Each number must verify they received a code via WhatsApp

**Important:** In development mode, messages can only be sent to numbers in this test list.

### Step 5: Verify Configuration

The backend will automatically:
1. Check for Meta WhatsApp credentials first (priority)
2. Fall back to Twilio if Meta credentials are not found
3. Fall back to custom API if neither is configured
4. Log OTPs to console if no service is configured

### Troubleshooting

#### Error: "Invalid phone number ID"
- Check that `WHATSAPP_PHONE_NUMBER_ID` is correct
- Verify the phone number is associated with your Meta App

#### Error: "Invalid access token"
- Verify your access token is valid and not expired
- Regenerate the token if needed
- For production, ensure you're using a permanent token or System User token

#### Error: "Recipient phone number not in test numbers list"
- This happens in development mode
- Add the recipient number to your test numbers list in Meta App dashboard
- Ensure the number is in international format without + sign

#### Error: "Message template issue"
- In production mode, you may need to use approved message templates
- Check Meta's template message requirements
- For OTP messages, consider creating a template message

#### No messages being sent
- Check server logs for detailed error messages
- Verify all environment variables are set correctly
- Check that the API version is correct
- Ensure your Meta App is in "Development" or "Live" mode

### Production Considerations

1. **Use Permanent Tokens**: Temporary tokens expire. Use System User tokens for production.

2. **Message Templates**: In production, you may need to use pre-approved message templates instead of free-form text.

3. **Rate Limits**: Meta has rate limits. Check the [official documentation](https://developers.facebook.com/docs/whatsapp/cloud-api/rate-limits).

4. **Webhooks**: Consider setting up webhooks to receive message status updates.

5. **Error Monitoring**: Monitor logs for API errors and set up alerts.

### Alternative: Twilio WhatsApp

If you prefer to use Twilio instead:

```env
WHATSAPP_ACCOUNT_SID=your_twilio_account_sid
WHATSAPP_AUTH_TOKEN=your_twilio_auth_token
WHATSAPP_FROM_NUMBER=whatsapp:+1234567890
```

### Testing

To test the WhatsApp integration:

1. Make a POST request to `/api/orders/send-otp` with:
   ```json
   {
     "phone": "501234567",
     "countryCode": "+970"
   }
   ```

2. Check server logs for detailed request/response information
3. Verify the OTP is received on the target WhatsApp number

### Logging

The service provides detailed logging:
- `📱` - WhatsApp sending attempt
- `🔗` - API URL being called
- `📤` - Request payload
- `📥` - Response status and data
- `✅` - Success messages
- `❌` - Error messages with detailed information

Check your server logs for debugging information.

