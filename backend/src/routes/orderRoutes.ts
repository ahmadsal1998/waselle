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
  createOrderWithFirebaseToken,
} from '../controllers/orderController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

// Public endpoints (no authentication required)
router.post('/estimate', estimateOrderPrice); // Public - users need to estimate before auth
// DEPRECATED: These endpoints use backend OTP generation (no SMS sending)
// Use Firebase Phone Auth instead via /create-with-firebase-token endpoint
router.post('/send-otp', sendOrderOTP); // DEPRECATED - Use Firebase Phone Auth
router.post('/verify-and-create', verifyOTPAndCreateOrder); // DEPRECATED - Use Firebase Phone Auth
router.post('/create-with-firebase-token', createOrderWithFirebaseToken); // ✅ RECOMMENDED - Create order with Firebase token

// Protected endpoints (require authentication)
router.post('/', authenticate, createOrder);
router.get('/', authenticate, getOrders);
router.get('/available', authenticate, authorize('driver'), getAvailableOrders);
router.post('/:orderId/accept', authenticate, authorize('driver'), acceptOrder);
router.patch('/:orderId/status', authenticate, updateOrderStatus);
router.get('/:orderId', authenticate, getOrderById);

export default router;
