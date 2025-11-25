import { Router } from 'express';
import {
  register,
  login,
  verifyOTP,
  verifyFirebaseToken,
  phoneLogin,
  resendOTP,
  getCurrentUser,
  sendPhoneOTP,
  verifyPhoneOTP,
} from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/verify-otp', verifyOTP);
router.post('/verify-firebase-token', verifyFirebaseToken); // DEPRECATED - kept for backward compatibility
router.post('/phone-login', phoneLogin); // DEPRECATED - kept for backward compatibility
router.post('/resend-otp', resendOTP);
// New SMS-based phone authentication endpoints (replaces Firebase)
router.post('/send-phone-otp', sendPhoneOTP);
router.post('/verify-phone-otp', verifyPhoneOTP);
router.get('/me', authenticate, getCurrentUser);

export default router;
