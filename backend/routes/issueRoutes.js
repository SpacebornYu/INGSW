// routes/issueRoutes.js
import express from 'express';
import { 
  createIssue, 
  getIssues, 
  getIssueById, 
  updateIssue,
  updateAssignees 
} from '../controllers/issueController.js';
import { auth } from '../middleware/auth.js';
import { isAdmin } from '../middleware/isAdmin.js';

const router = express.Router();

router.post('/', auth, createIssue);
router.get('/', auth, getIssues);
router.get('/:id', auth, getIssueById);
router.patch('/:id', auth, updateIssue);
router.patch('/:id/assignees', auth, isAdmin, updateAssignees);

export default router;
