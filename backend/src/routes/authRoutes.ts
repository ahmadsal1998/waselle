import { Router } from 'express';
import {
  register,
  login,
  verifyOTP,
  resendOTP,
  getCurrentUser,
} from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);
router.get('/me', authenticate, getCurrentUser);

export default router;
