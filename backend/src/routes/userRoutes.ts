import { Router } from 'express';
import {
  updateLocation,
  updateAvailability,
  getAllUsers,
  getUserById,
  getAvailableDrivers,
  updateProfilePicture,
  getMyBalance,
  updateFCMToken,
} from '../controllers/userController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.patch('/location', authenticate, updateLocation);
router.patch('/availability', authenticate, updateAvailability);
router.patch('/profile-picture', authenticate, updateProfilePicture);
router.post('/fcm-token', authenticate, updateFCMToken);
router.get('/balance', authenticate, getMyBalance);
router.get('/', authenticate, authorize('admin'), getAllUsers);
router.get('/drivers', authenticate, getAvailableDrivers);
router.get('/:userId', authenticate, getUserById);

export default router;
