import { Router } from 'express';
import { getSettings, updateSettings, getVehicleTypes, getLegalUrls } from '../controllers/settingsController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Public endpoints
router.get('/vehicle-types', getVehicleTypes);
router.get('/legal-urls', getLegalUrls);

// Admin-only endpoints
router.get('/', authenticate, getSettings);
router.put('/', authenticate, updateSettings);

export default router;

