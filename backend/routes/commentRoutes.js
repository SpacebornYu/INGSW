// routes/commentRoutes.js
import express from 'express';
import { getComments, createComment } from '../controllers/commentController.js';
import { auth } from '../middleware/auth.js';

const router = express.Router();

router.get('/issues/:id/comments', auth, getComments);
router.post('/issues/:id/comments', auth, createComment);

export default router;
