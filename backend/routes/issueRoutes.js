// routes/issueRoutes.js
import express from 'express';
import { 
  createIssue, 
  getIssues, 
  getIssueById, 
  updateIssue
} from '../controllers/issueController.js';
import { auth } from '../middleware/auth.js';
import upload from '../middleware/upload.js';

const router = express.Router();

router.post('/', auth, 
  (req, res, next) => {
    console.log('POST /issues - Inizio richiesta');
    next();
  },
  upload.array('images', 3), 
  (req, res, next) => {
    console.log('POST /issues - Upload completato (o saltato)');
    next();
  },
  createIssue
);
router.get('/', auth, getIssues);
router.get('/:id', auth, getIssueById);
router.patch('/:id', auth, updateIssue);

export default router;
