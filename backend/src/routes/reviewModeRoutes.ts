import { Router } from 'express';
import { checkReviewMode } from '../controllers/reviewModeController';

const router = Router();

// Public endpoint - no authentication required
router.get('/', checkReviewMode);

export default router;

