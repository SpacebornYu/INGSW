// routes/issueRoutes.js
import express from 'express';
import { 
  createIssue, 
  getIssues, 
  getIssueById, 
  updateIssue
} from '../controllers/issueController.js';
import { auth } from '../middleware/auth.js';

const router = express.Router();

router.post('/', auth, createIssue);
router.get('/', auth, getIssues);
router.get('/:id', auth, getIssueById);
router.patch('/:id', auth, updateIssue);

export default router;
