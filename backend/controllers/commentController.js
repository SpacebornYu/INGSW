// controllers/commentController.js
import Comment from '../models/Comment.js';
import Issue from '../models/Issue.js';
import User from '../models/User.js';

// GET /issues/:id/comments - lista commenti di una issue
export async function getComments(req, res) {
  try {
    const { id } = req.params;

    // Verifica che la issue esista
    const issue = await Issue.findByPk(id);
    if (!issue) {
      return res.status(404).json({ error: 'Issue non trovata' });
    }

    const comments = await Comment.findAll({
      where: { issueId: id },
      include: [
        { model: User, as: 'author', attributes: ['id', 'email'] },
      ],
      order: [['createdAt', 'ASC']],
    });

    res.json(comments);
  } catch (error) {
    console.error('Errore nel recupero commenti:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}

// POST /issues/:id/comments - aggiungi commento
export async function createComment(req, res) {
  try {
    const { id } = req.params;
    const { content } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Il contenuto del commento è obbligatorio' });
    }

    if (content.length > 1000) {
      return res.status(400).json({ error: 'Il commento non può superare i 1000 caratteri' });
    }

    // Verifica che la issue esista
    const issue = await Issue.findByPk(id);
    if (!issue) {
      return res.status(404).json({ error: 'Issue non trovata' });
    }

    const comment = await Comment.create({
      content: content.trim(),
      issueId: id,
      authorId: req.user.id,
    });

    // Ricarica con autore
    const commentWithAuthor = await Comment.findByPk(comment.id, {
      include: [
        { model: User, as: 'author', attributes: ['id', 'email'] },
      ],
    });

    res.status(201).json(commentWithAuthor);
  } catch (error) {
    console.error('Errore nella creazione commento:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}
export async function deleteComment(req, res) {
  try {
    const { id } = req.params;
    const comment = await Comment.findByPk(id);

    if (!comment) {
      return res.status(404).json({ error: 'Commento non trovato' });
    }

    // Controllo permessi: Solo l'autore può cancellare (o l'admin se vuoi)
    if (comment.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ error: 'Non autorizzato' });
    }

    await comment.destroy();
    res.json({ message: 'Commento eliminato' });
  } catch (error) {
    console.error('Errore eliminazione commento:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}