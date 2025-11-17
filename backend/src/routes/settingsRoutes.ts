import { Router } from 'express';
import { getSettings, updateSettings, getVehicleTypes } from '../controllers/settingsController';
import { authenticate } from '../middleware/auth';

const router = Router();

// Public endpoint to get available vehicle types
router.get('/vehicle-types', getVehicleTypes);

// Admin-only endpoints
router.get('/', authenticate, getSettings);
router.put('/', authenticate, updateSettings);

export default router;

