import { Resend } from 'resend';

const generateOTP = (): string => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Lazy initialization of Resend to ensure env vars are loaded
const getResend = (): Resend | null => {
  const resendApiKey = process.env.RESEND_API_KEY;
  if (!resendApiKey) {
    return null;
  }
  return new Resend(resendApiKey);
};

export const sendOTP = async (email: string, otp: string): Promise<void> => {
  try {
    const resend = getResend();
    if (!resend) {
      console.warn('⚠️  RESEND_API_KEY not configured. OTP will be logged to console only.');
      console.log(`📧 OTP for ${email}: ${otp}`);
      console.log('⚠️  In production, configure RESEND_API_KEY in .env file');
      return;
    }

    const fromEmail = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';
    
    const result = await resend.emails.send({
      from: fromEmail,
      to: email,
      subject: 'Delivery System - OTP Verification',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>OTP Verification</h2>
          <p>Your OTP code is:</p>
          <h1 style="color: #4CAF50; font-size: 32px;">${otp}</h1>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this code, please ignore this email.</p>
        </div>
      `,
    });
    console.log(`✅ OTP sent to ${email}`, result);
  } catch (error: any) {
    console.error('❌ Error sending OTP:', error);
    // Log detailed error information
    if (error?.message) {
      console.error('Error message:', error.message);
    }
    if (error?.response?.body) {
      console.error('Resend API error:', JSON.stringify(error.response.body, null, 2));
    }
    
    // Provide more specific error messages
    let errorMessage = 'Failed to send OTP email';
    if (error?.message?.includes('from')) {
      errorMessage = 'Invalid sender email. Please verify RESEND_FROM_EMAIL in .env file. For testing, use: onboarding@resend.dev';
    } else if (error?.response?.body?.message) {
      errorMessage = `Failed to send OTP: ${error.response.body.message}`;
    } else if (error?.message) {
      errorMessage = `Failed to send OTP: ${error.message}`;
    }
    
    throw new Error(errorMessage);
  }
};

export const generateAndSendOTP = async (email: string): Promise<string> => {
  const otp = generateOTP();
  await sendOTP(email, otp);
  return otp;
};

export { generateOTP };
