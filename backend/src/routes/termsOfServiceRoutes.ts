import { Router } from 'express';
import { getTermsOfService, updateTermsOfService } from '../controllers/termsOfServiceController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Public endpoint - anyone can view the terms of service
router.get('/', getTermsOfService);

// Admin-only endpoint - only admins can update the terms of service
router.put('/', authenticate, updateTermsOfService);

export default router;

