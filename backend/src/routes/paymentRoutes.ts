import { Router } from 'express';
import {
  addPayment,
  getDriverPayments,
  getDriverBalance,
} from '../controllers/paymentController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

// All routes require admin authentication
router.use(authenticate);
router.use(authorize('admin'));

router.post('/drivers/:driverId', addPayment);
router.get('/drivers/:driverId', getDriverPayments);
router.get('/drivers/:driverId/balance', getDriverBalance);

export default router;

