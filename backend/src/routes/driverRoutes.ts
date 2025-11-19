import { Router } from 'express';
import {
  getAllDrivers,
  getDriverById,
  createDriver,
  updateDriver,
  resetDriverPassword,
  toggleDriverStatus,
  deleteDriver,
} from '../controllers/driverController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

// All routes require admin authentication
router.use(authenticate);
router.use(authorize('admin'));

router.get('/', getAllDrivers);
router.get('/:driverId', getDriverById);
router.post('/', createDriver);
router.patch('/:driverId', updateDriver);
router.patch('/:driverId/password', resetDriverPassword);
router.patch('/:driverId/toggle-status', toggleDriverStatus);
router.delete('/:driverId', deleteDriver);

export default router;

