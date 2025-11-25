import https from 'https';
import http from 'http';
import { URL } from 'url';
import Settings from '../models/Settings';

/**
 * SMS Provider Utility
 * 
 * Integrates with HTC SMS Provider API
 * API Documentation: HTTP-API Manual v14.0
 * Endpoint: http://sms.htd.ps/API/SendSMS.aspx
 */

interface SMSConfig {
  apiUrl: string;
  apiKey: string;
  senderId: string;
}

// Get SMS provider configuration from environment variables
const getSMSConfig = (): SMSConfig => {
  const apiKey = process.env.SMS_API_KEY || process.env.SMS_API_ID;
  if (!apiKey) {
    throw new Error('SMS_API_KEY or SMS_API_ID environment variable is required');
  }

  return {
    apiUrl: process.env.SMS_API_URL || 'http://sms.htd.ps/API/SendSMS.aspx',
    apiKey: apiKey,
    senderId: process.env.SMS_SENDER_ID || 'SenderName',
  };
};

/**
 * Format phone number for HTC SMS API
 * HTC API expects format: 970XXXXXXXX (country code + number, no + or leading 0)
 * Example: +9700593202026 -> 970593202026
 */
const formatPhoneForHTC = (phoneNumber: string): string => {
  // Remove all non-digit characters
  let cleaned = phoneNumber.replace(/[^\d]/g, '');
  
  // If starts with 9720, remove the 0 after 972
  if (cleaned.startsWith('9720') && cleaned.length >= 13) {
    cleaned = '972' + cleaned.substring(4);
  }
  // If starts with 972 and length is 13, it's already correct (972 + 9 digits)
  // If starts with 972 and length is 12, it's missing the 0, but HTC expects without 0
  // So 972XXXXXXXXX (12 digits) is correct for HTC API
  
  // Ensure it starts with country code
  if (!cleaned.startsWith('972')) {
    // If starts with 0, replace with 972
    if (cleaned.startsWith('0')) {
      cleaned = '972' + cleaned.substring(1);
    } else {
      // Assume it's local number, prepend 972
      cleaned = '972' + cleaned;
    }
  }
  
  // Remove leading zero after country code if present
  if (cleaned.startsWith('9720')) {
    cleaned = '972' + cleaned.substring(4);
  }
  
  return cleaned;
};

/**
 * Get OTP message template from Settings and replace placeholders
 * @param otp - 6-digit OTP code
 * @param language - Optional language code ('ar' for Arabic, 'en' for English, or undefined to use default from settings)
 * @returns Promise<string> - Formatted message with OTP inserted
 */
const getOTPMessage = async (otp: string, language?: string): Promise<string> => {
  try {
    const settings = await Settings.getSettings();
    let template: string | undefined;
    
    // Determine which language to use
    // Priority: 1. Explicit language parameter, 2. Settings default, 3. English
    const targetLanguage = language || settings.otpMessageLanguage || 'en';
    
    // Use Arabic template if target language is 'ar' and Arabic template exists
    if (targetLanguage === 'ar' && settings.otpMessageTemplateAr) {
      template = settings.otpMessageTemplateAr;
    } else {
      // Use default/English template
      template = settings.otpMessageTemplate;
    }
    
    // Fallback to default if template is not set
    if (!template) {
      template = targetLanguage === 'ar' 
        ? 'رمز التحقق الخاص بك هو: ${otp}. هذا الرمز صالح لمدة 10 دقائق فقط.'
        : 'Your OTP code is: ${otp}. This code will expire in 10 minutes.';
    }
    
    // Replace ${otp} placeholder with actual OTP code
    const message = template.replace(/\$\{otp\}/g, otp);
    
    return message;
  } catch (error: any) {
    console.error('Error fetching OTP message template:', error);
    // Fallback to default message if Settings fetch fails
    const defaultLanguage = language || 'en';
    const defaultMessage = defaultLanguage === 'ar'
      ? 'رمز التحقق الخاص بك هو: ${otp}. هذا الرمز صالح لمدة 10 دقائق فقط.'
      : 'Your OTP code is: ${otp}. This code will expire in 10 minutes.';
    return defaultMessage.replace(/\$\{otp\}/g, otp);
  }
};

/**
 * Send OTP via SMS using HTC SMS Provider API
 * API Format: GET http://sms.htd.ps/API/SendSMS.aspx?id={apiKey}&sender={sender}&to={phone}&msg={message}
 * 
 * @param phoneNumber - Phone number in international format (e.g., +9700593202026)
 * @param otp - 6-digit OTP code
 * @param language - Optional language code ('ar' for Arabic, 'en' for English, or undefined for default)
 * @returns Promise<void>
 */
export const sendSMSOTP = async (phoneNumber: string, otp: string, language?: string): Promise<void> => {
  const config = getSMSConfig();
  
  try {
    // Format phone number for HTC API (970XXXXXXXX format, no + or leading 0)
    const formattedPhone = formatPhoneForHTC(phoneNumber);
    
    // Get OTP message template from Settings and replace placeholders
    const message = await getOTPMessage(otp, language);
    
    // Build HTC API URL with query parameters
    const url = new URL(config.apiUrl);
    url.searchParams.set('id', config.apiKey);
    url.searchParams.set('sender', config.senderId);
    url.searchParams.set('to', formattedPhone);
    url.searchParams.set('msg', message);
    
    // Make GET request to HTC SMS API
    return new Promise((resolve, reject) => {
      const urlObj = new URL(url.toString());
      const isHttps = urlObj.protocol === 'https:';
      const client = isHttps ? https : http;

      const requestOptions = {
        hostname: urlObj.hostname,
        port: urlObj.port || (isHttps ? 443 : 80),
        path: urlObj.pathname + urlObj.search,
        method: 'GET',
      };

      const req = client.request(requestOptions, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          // HTC API returns plain text response
          // Success format: Usually empty or success message
          // Error format: H###|Error message (e.g., H006|Invalid DESTINATION Parameter)
          
          const responseText = data.trim();
          
          // Log the raw response for debugging
          console.log(`📥 HTC SMS API Response: "${responseText}"`);
          
          // Check for error codes (H### format)
          if (responseText.startsWith('H')) {
            const errorMatch = responseText.match(/^H\d+\|(.+)$/);
            const errorMessage = errorMatch ? errorMatch[1] : responseText;
            
            // Map common HTC error codes
            let userFriendlyMessage = errorMessage;
            if (responseText.startsWith('H006')) {
              userFriendlyMessage = 'Invalid phone number format';
            } else if (responseText.startsWith('H001') || responseText.startsWith('H002')) {
              userFriendlyMessage = 'SMS API authentication failed. Please check SMS_API_KEY.';
            } else if (responseText.startsWith('H003')) {
              userFriendlyMessage = 'Invalid sender name';
            } else if (responseText.startsWith('H004')) {
              userFriendlyMessage = 'Message content error';
            } else if (responseText.startsWith('H005')) {
              userFriendlyMessage = 'Insufficient credits';
            } else if (responseText.startsWith('H008')) {
              userFriendlyMessage = 'Sender ID not approved. Please use an approved sender ID or contact HTC SMS provider to approve your sender ID.';
            }
            
            reject(new Error(`SMS API Error: ${userFriendlyMessage} (${responseText})`));
            return;
          }
          
          // Check for other error messages (like "Sender Not Approved")
          if (responseText.toLowerCase().includes('error') || 
              responseText.toLowerCase().includes('invalid') ||
              responseText.toLowerCase().includes('not approved') ||
              responseText.toLowerCase().includes('failed')) {
            reject(new Error(`SMS API Error: ${responseText}`));
            return;
          }
          
          // Success (empty response or success message)
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            console.log(`✅ SMS OTP sent to ${phoneNumber} (formatted: ${formattedPhone})`);
            if (responseText) {
              console.log(`   API Response: ${responseText}`);
            }
            resolve();
          } else {
            reject(new Error(`SMS API returned status ${res.statusCode || 'unknown'}: ${responseText}`));
          }
        });
      });

      req.on('error', (error) => {
        console.error('❌ Network error sending SMS:', error);
        reject(new Error(`Unable to reach SMS service: ${error.message}`));
      });

      req.end();
    });
  } catch (error: any) {
    console.error('❌ Error sending SMS OTP:', error);
    
    // Provide more specific error messages
    let errorMessage = 'Failed to send SMS OTP';
    
    if (error.message) {
      errorMessage = error.message;
    } else if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
      errorMessage = 'Unable to reach SMS service. Please check SMS_API_URL configuration.';
    }
    
    throw new Error(errorMessage);
  }
};

/**
 * Verify OTP
 * Note: HTC SMS Provider doesn't have a verification endpoint
 * OTP verification is handled by the backend by comparing stored OTP
 * @param phoneNumber - Phone number
 * @param otp - OTP code to verify
 * @returns Promise<boolean>
 */
export const verifySMSOTP = async (phoneNumber: string, otp: string): Promise<boolean> => {
  // HTC SMS Provider doesn't have a verification endpoint
  // Verification is handled by comparing with stored OTP in the database
  // This function is kept for consistency but always returns true
  // Actual verification happens in authController.ts
  return true;
};

