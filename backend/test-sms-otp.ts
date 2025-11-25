/**
 * Test script for SMS OTP functionality
 * 
 * Usage:
 *   npm run test:sms
 *   OR
 *   tsx test-sms-otp.ts
 * 
 * Make sure to set environment variables:
 *   SMS_API_URL=http://sms.htd.ps/API/SendSMS.aspx
 *   SMS_API_KEY=your_api_key_here
 *   SMS_SENDER_ID=SenderName
 */

import dotenv from 'dotenv';
import { sendSMSOTP } from './src/utils/smsProvider';

// Load environment variables
dotenv.config();

async function testSendOTP() {
  const phoneNumber = '+9720593202026';
  const testOTP = '123456'; // Test OTP code

  console.log('🧪 Testing SMS OTP Sending...\n');
  console.log(`📱 Phone Number: ${phoneNumber}`);
  console.log(`🔑 OTP Code: ${testOTP}\n`);

  // Check configuration
  console.log('📋 Configuration:');
  console.log(`   SMS_API_URL: ${process.env.SMS_API_URL || 'http://sms.htd.ps/API/SendSMS.aspx'}`);
  console.log(`   SMS_API_KEY: ${process.env.SMS_API_KEY ? '***' + process.env.SMS_API_KEY.slice(-4) : 'NOT SET'}`);
  console.log(`   SMS_SENDER_ID: ${process.env.SMS_SENDER_ID || 'SenderName'}\n`);

  if (!process.env.SMS_API_KEY) {
    console.error('❌ ERROR: SMS_API_KEY is not set in environment variables!');
    console.error('   Please set SMS_API_KEY in your .env file');
    process.exit(1);
  }

  try {
    console.log('📤 Sending OTP via SMS...\n');
    await sendSMSOTP(phoneNumber, testOTP);
    console.log('\n✅ SUCCESS: OTP sent successfully!');
    console.log(`   Check your phone (${phoneNumber}) for the SMS message.`);
  } catch (error: any) {
    console.error('\n❌ ERROR: Failed to send OTP');
    console.error(`   ${error.message}`);
    
    if (error.message.includes('Invalid phone number')) {
      console.error('\n💡 Tip: Make sure the phone number format is correct.');
      console.error('   Expected format: +9720XXXXXXXX');
    } else if (error.message.includes('authentication')) {
      console.error('\n💡 Tip: Check your SMS_API_KEY in .env file');
    } else if (error.message.includes('Unable to reach')) {
      console.error('\n💡 Tip: Check your internet connection and SMS_API_URL');
    }
    
    process.exit(1);
  }
}

// Run the test
testSendOTP().catch((error) => {
  console.error('Unexpected error:', error);
  process.exit(1);
});

