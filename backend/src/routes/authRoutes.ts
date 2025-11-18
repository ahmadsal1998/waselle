import { Router } from 'express';
import {
  register,
  login,
  verifyOTP,
  resendOTP,
  verifyFirebaseToken,
  getCurrentUser,
} from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);
router.post('/verify-firebase-token', verifyFirebaseToken); // New Firebase token verification endpoint
router.get('/me', authenticate, getCurrentUser);

export default router;
