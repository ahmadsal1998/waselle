import { Router } from 'express';
import { getPrivacyPolicy, updatePrivacyPolicy } from '../controllers/privacyPolicyController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Public endpoint - anyone can view the privacy policy
router.get('/', getPrivacyPolicy);

// Admin-only endpoint - only admins can update the privacy policy
router.put('/', authenticate, updatePrivacyPolicy);

export default router;

