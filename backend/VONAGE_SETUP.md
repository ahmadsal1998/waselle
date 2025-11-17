# Vonage WhatsApp OTP Setup Guide

This guide explains how to configure WhatsApp OTP delivery using Vonage (formerly Nexmo) for reliable and fast OTP delivery.

## Why Vonage?

- **Reliable Delivery**: High delivery rates with global coverage
- **No Rate Limit Issues**: Better rate limits compared to many alternatives
- **Easy Onboarding**: Simple setup process
- **WhatsApp Business API**: Native support for WhatsApp Business messaging
- **Production Ready**: Suitable for production environments

## Prerequisites

1. A Vonage account - [Sign up here](https://dashboard.nexmo.com/sign-up)
2. API Key and API Secret from your Vonage dashboard
3. A WhatsApp Business-enabled phone number (required for WhatsApp delivery)

## Step 1: Create a Vonage Account

1. Go to [Vonage Dashboard](https://dashboard.nexmo.com/sign-up)
2. Create a new account and verify your email
3. Complete the account setup process

## Step 2: Get Your API Credentials

1. Log in to your [Vonage Dashboard](https://dashboard.nexmo.com/)
2. Navigate to **Settings** → **API Credentials**
3. Copy your:
   - **API Key** (also called API Key ID)
   - **API Secret**  

⚠️ **Important**: Keep these credentials secure. Never commit them to version control.

## Step 3: Enable WhatsApp Business on Your Vonage Account

**Important**: To send OTP via WhatsApp, you need to set up WhatsApp Business API through Vonage.

### Option A: Using Vonage's WhatsApp Business Account (Recommended)

1. Go to your [Vonage Dashboard](https://dashboard.nexmo.com/)
2. Navigate to **Messages** → **WhatsApp**
3. Follow the onboarding process to set up your WhatsApp Business Account
4. Complete the WhatsApp Business verification process
5. Get your WhatsApp-enabled phone number from Vonage
6. Note the phone number (you'll use this as `VONAGE_FROM_NUMBER`)

### Option B: Using Your Own WhatsApp Business Number

If you already have a WhatsApp Business number:

1. Go to your [Vonage Dashboard](https://dashboard.nexmo.com/)
2. Navigate to **Messages** → **WhatsApp**
3. Link your existing WhatsApp Business Account
4. Complete the verification process
5. Use your verified WhatsApp Business number as `VONAGE_FROM_NUMBER`

**Note**: The phone number must be enabled for WhatsApp Business in your Vonage account. Regular SMS numbers won't work for WhatsApp delivery.

For detailed instructions, see: [Vonage WhatsApp Business Setup Guide](https://api.support.vonage.com/hc/en-us/articles/20310879407900-Getting-started-with-Vonage-s-WhatsApp-Business-Account-Hosted-Embedded-Sign-Up-for-partners-End-Customers)

## Step 4: Configure Environment Variables

Add the following to your `.env` file in the `backend` directory:

```env
# Vonage WhatsApp Configuration
VONAGE_API_KEY=your_api_key_here
VONAGE_API_SECRET=your_api_secret_here
VONAGE_FROM_NUMBER=your_whatsapp_business_number_here  # e.g., +1234567890 (must be WhatsApp-enabled)
```

**Alternative variable names (also supported):**
```env
VONAGE_SENDER_ID=your_whatsapp_business_number_here
VONAGE_BRAND_NAME=Your Brand Name  # Optional brand name
```

### Environment Variables Explained

- **VONAGE_API_KEY** (Required): Your Vonage API key
- **VONAGE_API_SECRET** (Required): Your Vonage API secret
- **VONAGE_FROM_NUMBER** or **VONAGE_SENDER_ID** (Required for WhatsApp): 
  - Must be a WhatsApp Business-enabled phone number (e.g., `+1234567890`)
  - The number must be registered and enabled for WhatsApp Business in your Vonage dashboard
  - Regular SMS numbers will not work for WhatsApp delivery
- **VONAGE_BRAND_NAME** (Optional): Brand name for your messages

## Step 5: Test the Integration

### Using the API

Make a POST request to `/api/orders/send-otp`:

```json
{
  "phone": "501234567",
  "countryCode": "+970"
}
```

### Expected Response

**Success:**
```json
{
  "message": "OTP sent successfully via WhatsApp",
  "phone": "+970501234567"
}
```

**Development Mode (if WhatsApp fails):**
```json
{
  "message": "OTP generated. Check console for OTP code.",
  "phone": "+970501234567",
  "otp": "123456"  // Only in development mode
}
```

## Phone Number Format

The service expects phone numbers in **E.164 format**:
- ✅ Correct: `+970501234567`, `+1234567890`
- ❌ Incorrect: `970501234567`, `0501234567`, `(050) 123-4567`

The service automatically normalizes phone numbers by adding `+` if missing.

## Rate Limits

Vonage has generous rate limits:
- **Standard accounts**: Up to 5,000 messages per second
- **Higher tiers available** for enterprise needs

This should be more than sufficient for most OTP use cases.

## Troubleshooting

### Error: "Vonage API error: authentication-failed"

**Solution:**
- Verify your `VONAGE_API_KEY` and `VONAGE_API_SECRET` are correct
- Make sure there are no extra spaces in the environment variables
- Check that your account is active

### Error: "Invalid phone number format"

**Solution:**
- Ensure phone numbers are in E.164 format (e.g., `+970501234567`)
- Include country code
- Remove any spaces, dashes, or parentheses

### Error: "WhatsApp number not enabled" or "Invalid WhatsApp number"

**Solution:**
- Verify that your `VONAGE_FROM_NUMBER` is enabled for WhatsApp Business in your Vonage dashboard
- Go to **Messages** → **WhatsApp** in your Vonage dashboard
- Ensure your WhatsApp Business Account is fully set up and verified
- The number must be registered as a WhatsApp Business number, not just a regular SMS number

### Error: "Insufficient credit"

**Solution:**
- Top up your Vonage account in the dashboard
- Check your account balance at **Account** → **Balance**

### Error: "Rate limit exceeded"

**Solution:**
- This is rare with Vonage, but if it happens:
  - Wait a few seconds before retrying
  - Consider upgrading your account tier
  - Check if you're sending too many messages too quickly

### Messages Not Being Received

**Possible causes:**
1. **Invalid phone number**: Check the format
2. **WhatsApp not enabled**: The sender number must be WhatsApp Business-enabled
3. **Recipient not on WhatsApp**: The recipient must have WhatsApp installed
4. **Country restrictions**: Some countries may have restrictions
5. **Insufficient account credit**: Check your balance
6. **WhatsApp Business Account not verified**: Complete the verification process

**Debug steps:**
1. Check server logs for detailed error messages
2. Verify the phone number is correct and in E.164 format
3. Ensure your `VONAGE_FROM_NUMBER` is enabled for WhatsApp Business
4. Test with a different phone number that has WhatsApp installed
5. Check your Vonage dashboard for message delivery status
6. Verify your WhatsApp Business Account status in Vonage dashboard

### Testing Without Actual WhatsApp

In development mode, if Vonage credentials are not configured, the system will:
- Log the OTP to the console
- Still generate and store the OTP in the database
- Return the OTP in the API response (development mode only)

## Logging

The service provides detailed logging:

- `📱` - WhatsApp sending attempt
- `🔗` - API URL being called
- `📤` - Request payload (sanitized - API key partially hidden)
- `📥` - Response status and data
- `✅` - Success messages with message UUID
- `❌` - Error messages with detailed information

Check your server logs for debugging information.

## Production Best Practices

1. **Use WhatsApp Business Numbers**: Always use a dedicated WhatsApp Business-enabled number in production
2. **Monitor Delivery**: Set up webhooks to monitor message delivery status
3. **Error Handling**: Implement proper retry logic for failed messages
4. **Rate Limiting**: Implement client-side rate limiting to prevent abuse
5. **Message Templates**: Consider using pre-approved WhatsApp message templates for better deliverability
6. **Security**: Never log full API secrets in production logs
7. **Monitoring**: Set up alerts for failed WhatsApp deliveries
8. **WhatsApp Business Verification**: Ensure your WhatsApp Business Account is fully verified

## Cost Considerations

Vonage pricing is typically:
- Pay-as-you-go model
- Competitive rates per message
- No monthly fees (unless using specific features)
- Free tier available for testing

Check [Vonage Pricing](https://www.vonage.com/communications-apis/pricing/) for current rates.

## Webhooks (Optional)

For production, you may want to set up webhooks to receive:
- Delivery receipts
- Message status updates
- Error notifications

See [Vonage Webhooks Documentation](https://developer.vonage.com/en/messages/overview#webhooks) for setup.

## WhatsApp vs SMS

This service is configured to send OTP via **WhatsApp** by default. The system uses Vonage's Messages API with the `whatsapp` channel.

If you need to send via SMS instead, you can:
1. Use the `sendOTPViaSMS` function from `smsService.ts`
2. Change the `channel` parameter from `'whatsapp'` to `'sms'` in the API call
3. Use a regular SMS-enabled number instead of a WhatsApp Business number

**Note**: The current implementation sends OTP via WhatsApp. Ensure your `VONAGE_FROM_NUMBER` is enabled for WhatsApp Business.

## Support

- **Vonage Documentation**: https://developer.vonage.com/en/messages/overview
- **Vonage Support**: https://help.nexmo.com/
- **API Status**: https://status.nexmo.com/

## Migration from Twilio/WhatsApp

If you're migrating from Twilio or Meta WhatsApp:
1. Remove old environment variables (e.g., `WHATSAPP_*`, `TWILIO_*`)
2. Add Vonage credentials as shown above
3. Restart your backend server
4. Test with a few OTP requests
5. Monitor logs for any issues

The OTP generation and storage logic remains unchanged - only the delivery method has changed.

