import { Router } from 'express';
import {
  createOrder,
  getOrders,
  getAvailableOrders,
  acceptOrder,
  updateOrderStatus,
  getOrderById,
  estimateOrderPrice,
  sendOrderOTP,
  verifyOTPAndCreateOrder,
} from '../controllers/orderController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

// Public endpoints (no authentication required)
router.post('/estimate', estimateOrderPrice); // Public - users need to estimate before auth
router.post('/send-otp', sendOrderOTP); // Public - send OTP for order verification
router.post('/verify-and-create', verifyOTPAndCreateOrder); // Public - verify OTP and create order

// Protected endpoints (require authentication)
router.post('/', authenticate, createOrder);
router.get('/', authenticate, getOrders);
router.get('/available', authenticate, authorize('driver'), getAvailableOrders);
router.post('/:orderId/accept', authenticate, authorize('driver'), acceptOrder);
router.patch('/:orderId/status', authenticate, updateOrderStatus);
router.get('/:orderId', authenticate, getOrderById);

export default router;
