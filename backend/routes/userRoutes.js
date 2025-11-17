// routes/userRoutes.js
import express from 'express';
import { getMe, createUser } from '../controllers/userController.js';
import { auth } from '../middleware/auth.js';
import { isAdmin } from '../middleware/isAdmin.js';

const router = express.Router();

router.get('/me', auth, getMe);
router.post('/admin/users', auth, isAdmin, createUser);

export default router;
