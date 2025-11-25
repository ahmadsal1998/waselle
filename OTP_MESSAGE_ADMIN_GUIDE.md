# OTP Message Template - Admin Guide

## Overview

The OTP SMS message can now be customized by administrators without modifying backend code. The message template is stored in the Settings database and can be updated via the admin API.

## Features

- ✅ **Fully Customizable**: Admin can change the entire OTP message text
- ✅ **Dynamic OTP Insertion**: Use `${otp}` placeholder to insert the OTP code
- ✅ **Immediate Effect**: Changes take effect immediately for all new OTP messages
- ✅ **Backward Compatible**: Default message is used if no custom template is set
- ✅ **Validation**: System validates that template contains required placeholder

## Default Message

If no custom template is set, the default message is:
```
Your OTP code is: ${otp}. This code will expire in 10 minutes.
```

## Placeholders

### `${otp}`
- **Required**: Must be present in the template
- **Purpose**: Replaced with the actual 6-digit OTP code
- **Example**: `Your code is ${otp}` → `Your code is 123456`

## API Endpoints

### Get Current Settings (including OTP template)

**Endpoint:** `GET /api/settings`

**Authentication:** Required (Admin only)

**Response:**
```json
{
  "settings": {
    "otpMessageTemplate": "Your OTP code is: ${otp}. This code will expire in 10 minutes.",
    // ... other settings
  }
}
```

### Update OTP Message Template

**Endpoint:** `PUT /api/settings`

**Authentication:** Required (Admin only)

**Request Body:**
```json
{
  "otpMessageTemplate": "Your verification code is ${otp}. Valid for 10 minutes only."
}
```

**Response:**
```json
{
  "message": "Settings updated successfully",
  "settings": {
    "otpMessageTemplate": "Your verification code is ${otp}. Valid for 10 minutes only.",
    // ... other settings
  }
}
```

## Validation Rules

1. **Must be a string**: `otpMessageTemplate` must be a string type
2. **Must contain `${otp}`**: Template must include the `${otp}` placeholder
3. **Length**: Must be between 10 and 500 characters
4. **Trimmed**: Leading and trailing whitespace is automatically removed

## Example Templates

### Simple Template
```json
{
  "otpMessageTemplate": "Your code: ${otp}"
}
```
**Result:** `Your code: 123456`

### Detailed Template
```json
{
  "otpMessageTemplate": "Welcome! Your OTP verification code is ${otp}. This code expires in 10 minutes. Do not share this code with anyone."
}
```
**Result:** `Welcome! Your OTP verification code is 123456. This code expires in 10 minutes. Do not share this code with anyone.`

### Multilingual Template (Arabic)
```json
{
  "otpMessageTemplate": "رمز التحقق الخاص بك هو: ${otp}. صالح لمدة 10 دقائق فقط."
}
```
**Result:** `رمز التحقق الخاص بك هو: 123456. صالح لمدة 10 دقائق فقط.`

### Branded Template
```json
{
  "otpMessageTemplate": "[YourApp] Your verification code is ${otp}. Valid for 10 minutes."
}
```
**Result:** `[YourApp] Your verification code is 123456. Valid for 10 minutes.`

## SMS Length Considerations

- **SMS Standard**: Standard SMS messages are limited to 160 characters
- **Template Length**: Template can be up to 500 characters (to account for longer messages)
- **Actual Message**: The final message (after OTP insertion) should ideally be ≤ 160 characters
- **Long Messages**: If the message exceeds 160 characters, it may be split into multiple SMS (costs more)

### Recommended Template Length

Keep templates under **150 characters** to ensure single SMS delivery:
- OTP code: 6 characters
- Placeholder `${otp}`: 6 characters
- Remaining text: ~144 characters

**Example (144 chars):**
```
Your OTP code is ${otp}. This code will expire in 10 minutes. Do not share this code with anyone. If you didn't request this code, please ignore this message.
```

## Testing

### Test via API

1. **Get current template:**
```bash
curl -X GET http://localhost:5001/api/settings \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

2. **Update template:**
```bash
curl -X PUT http://localhost:5001/api/settings \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "otpMessageTemplate": "Your code is ${otp}. Valid for 10 minutes."
  }'
```

3. **Test OTP sending:**
```bash
curl -X POST http://localhost:5001/api/auth/send-phone-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+9720593202026"}'
```

### Test via Admin Dashboard

If you have an admin dashboard:
1. Navigate to Settings page
2. Find "OTP Message Template" field
3. Enter your custom template
4. Save settings
5. Send a test OTP to verify the message

## Error Handling

### Missing Placeholder
```json
{
  "message": "otpMessageTemplate must contain ${otp} placeholder for the OTP code"
}
```

### Invalid Length
```json
{
  "message": "otpMessageTemplate must be 500 characters or less"
}
```

### Too Short
```json
{
  "message": "otpMessageTemplate must be at least 10 characters"
}
```

## Implementation Details

### Backend Changes

1. **Settings Model** (`backend/src/models/Settings.ts`):
   - Added `otpMessageTemplate` field
   - Default value: `'Your OTP code is: ${otp}. This code will expire in 10 minutes.'`

2. **SMS Provider** (`backend/src/utils/smsProvider.ts`):
   - Fetches template from Settings before sending SMS
   - Replaces `${otp}` placeholder with actual OTP code
   - Falls back to default if Settings fetch fails

3. **Settings Controller** (`backend/src/controllers/settingsController.ts`):
   - Validates template format and content
   - Ensures `${otp}` placeholder is present
   - Updates template in database

### Database Migration

The `otpMessageTemplate` field is automatically added to existing Settings documents when `Settings.getSettings()` is called. No manual migration is required.

## Best Practices

1. **Keep it Short**: Aim for ≤ 150 characters to ensure single SMS delivery
2. **Clear Instructions**: Tell users what the code is for and when it expires
3. **Security Warning**: Remind users not to share the code
4. **Brand Consistency**: Include your app/brand name if desired
5. **Test First**: Test with a real phone number before deploying
6. **Monitor Length**: Check actual message length after OTP insertion

## Troubleshooting

### Template Not Updating
- Verify you're authenticated as admin
- Check that the request includes `otpMessageTemplate` in the body
- Verify the template contains `${otp}` placeholder

### OTP Not Appearing in Message
- Ensure template contains `${otp}` (case-sensitive)
- Check that template was saved successfully
- Verify Settings are being fetched correctly

### Message Too Long
- Reduce template text
- Remove unnecessary words
- Consider splitting into multiple messages if needed

## Support

For issues or questions:
1. Check backend logs for error messages
2. Verify Settings API responses
3. Test template with a simple example first
4. Ensure admin authentication is working

