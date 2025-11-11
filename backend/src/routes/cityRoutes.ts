import { Router } from 'express';
import {
  createCity,
  deleteCity,
  getCities,
  updateCity,
} from '../controllers/cityController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.get('/', getCities);

router.use(authenticate, authorize('admin'));

router.post('/', createCity);
router.patch('/:id', updateCity);
router.delete('/:id', deleteCity);

export default router;

