import { Router } from 'express';
import {
  createVillage,
  deleteVillage,
  getVillages,
  updateVillage,
} from '../controllers/villageController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.get('/', getVillages);

router.use(authenticate, authorize('admin'));

router.post('/', createVillage);
router.patch('/:id', updateVillage);
router.delete('/:id', deleteVillage);

export default router;

