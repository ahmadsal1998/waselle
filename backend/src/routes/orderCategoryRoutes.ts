import { Router } from 'express';
import {
  createOrderCategory,
  deleteOrderCategory,
  getOrderCategories,
  updateOrderCategory,
} from '../controllers/orderCategoryController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.get('/', getOrderCategories);

router.use(authenticate, authorize('admin'));

router.post('/', createOrderCategory);
router.patch('/:id', updateOrderCategory);
router.delete('/:id', deleteOrderCategory);

export default router;


