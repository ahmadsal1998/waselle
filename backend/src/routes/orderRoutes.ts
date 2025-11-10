import { Router } from 'express';
import {
  createOrder,
  getOrders,
  getAvailableOrders,
  acceptOrder,
  updateOrderStatus,
  getOrderById,
  estimateOrderPrice,
} from '../controllers/orderController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.post('/estimate', authenticate, estimateOrderPrice);
router.post('/', authenticate, createOrder);
router.get('/', authenticate, getOrders);
router.get('/available', authenticate, authorize('driver'), getAvailableOrders);
router.post('/:orderId/accept', authenticate, authorize('driver'), acceptOrder);
router.patch('/:orderId/status', authenticate, updateOrderStatus);
router.get('/:orderId', authenticate, getOrderById);

export default router;
