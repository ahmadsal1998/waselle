import { Router } from 'express';
import { generateZegoToken } from '../controllers/zegoController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Generate Zego token for voice call
// Requires authentication - only authenticated users can generate tokens
router.post('/token', authenticate, generateZegoToken);

export default router;

