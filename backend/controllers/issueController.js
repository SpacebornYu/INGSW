// controllers/issueController.js
import { Op } from 'sequelize';
import Issue from '../models/Issue.js';
import User from '../models/User.js';
import Tag from '../models/Tag.js';
import Comment from '../models/Comment.js';

// POST /issues - crea una nuova issue
// backend/controllers/issueController.js

export async function createIssue(req, res) {
  try {
    // MODIFICA 1: Aggiungi 'imageUrl' nella lista delle cose da leggere
    const { title, description, type, priority, tags, imageUrl } = req.body;

    if (!title || !description || !type) {
      return res.status(400).json({ error: 'Titolo, descrizione e tipo sono obbligatori' });
    }

    // Controllo priorità aggiornato
    if (priority && !['VERY LOW', 'LOW', 'MEDIUM', 'HIGH', 'VERY HIGH', 'URGENT'].includes(priority)) {
      return res.status(400).json({ error: 'Priorità non valida' });
    }

    const issue = await Issue.create({
      title,
      description,
      type,
      priority: priority || null,
      status: 'TODO',
      creatorId: req.user.id,
      // MODIFICA 2: Salva l'URL nel database (o null se non c'è)
      imageUrl: imageUrl || null,
    });

    // Gestione tag
    if (tags && Array.isArray(tags) && tags.length > 0) {
      const tagInstances = await Promise.all(
        tags.map(tagName => 
          Tag.findOrCreate({ where: { name: tagName.trim() } })
            .then(([tag]) => tag)
        )
      );
      await issue.addTags(tagInstances);
    }

    const issueWithRelations = await Issue.findByPk(issue.id, {
      include: [
        { model: User, as: 'creator', attributes: ['id', 'email'] },
        { model: Tag, as: 'tags', attributes: ['id', 'name'], through: { attributes: [] } },
      ],
    });

    res.status(201).json(issueWithRelations);
  } catch (error) {
    console.error('Errore nella creazione issue:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}
// GET /issues - lista issue con filtri
export async function getIssues(req, res) {
  try {
    const { 
      type, status, priority, creatorId, tag, search, 
      sortBy = 'createdAt', order = 'desc' 
    } = req.query;

    const where = {};

    if (type) where.type = type;
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (creatorId) where.creatorId = creatorId;
    
    if (search) {
      where[Op.or] = [
        { title: { [Op.iLike]: `%${search}%` } },
        { description: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const include = [
      { model: User, as: 'creator', attributes: ['id', 'email'] },
      { model: Tag, as: 'tags', attributes: ['id', 'name'], through: { attributes: [] } },
    ];

    // Filtro per tag (più complesso)
    if (tag) {
      include[1].where = { name: tag };
      include[1].required = true;
    }

    const issues = await Issue.findAll({
      where,
      include,
      order: [[sortBy, order.toUpperCase()]],
    });

    res.json(issues);
  } catch (error) {
    console.error('Errore nel recupero issue:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}

// GET /issues/:id - dettaglio issue
export async function getIssueById(req, res) {
  try {
    const { id } = req.params;

    const issue = await Issue.findByPk(id, {
      include: [
        { model: User, as: 'creator', attributes: ['id', 'email'] },
        { model: Tag, as: 'tags', attributes: ['id', 'name'], through: { attributes: [] } },
        { 
          model: Comment, 
          include: [{ model: User, as: 'author', attributes: ['id', 'email'] }],
          order: [['createdAt', 'ASC']],
        },
      ],
    });

    if (!issue) {
      return res.status(404).json({ error: 'Issue non trovata' });
    }

    res.json(issue);
  } catch (error) {
    console.error('Errore nel recupero issue:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}

// PATCH /issues/:id - aggiorna issue
export async function updateIssue(req, res) {
  try {
    const { id } = req.params;
    const { title, description, type, priority, status, tags } = req.body;

    const issue = await Issue.findByPk(id);
    
    if (!issue) {
      return res.status(404).json({ error: 'Issue non trovata' });
    }

    // Aggiorna campi
    if (title) issue.title = title;
    if (description) issue.description = description;
    if (type) {
      if (!['QUESTION', 'BUG', 'DOCUMENTATION', 'FEATURE'].includes(type)) {
        return res.status(400).json({ error: 'Tipo non valido' });
      }
      issue.type = type;
    }
    if (priority !== undefined) {
      // Aggiungi le nuove priorità alla lista di controllo:
    if (priority && !['VERY LOW', 'LOW', 'MEDIUM', 'HIGH', 'VERY HIGH', 'URGENT'].includes(priority)) {
  return res.status(400).json({ error: 'Priorità non valida' });
}
      issue.priority = priority;
    }
    if (status) {
      if (!['TODO', 'IN_PROGRESS', 'DONE'].includes(status)) {
        return res.status(400).json({ error: 'Stato non valido' });
      }
      issue.status = status;
    }

    await issue.save();

    // Aggiorna tag se presenti
    if (tags && Array.isArray(tags)) {
      const tagInstances = await Promise.all(
        tags.map(tagName => 
          Tag.findOrCreate({ where: { name: tagName.trim() } })
            .then(([tag]) => tag)
        )
      );
      await issue.setTags(tagInstances);
    }

    // Ricarica con relazioni
    const updated = await Issue.findByPk(id, {
      include: [
        { model: User, as: 'creator', attributes: ['id', 'email'] },
        { model: Tag, as: 'tags', attributes: ['id', 'name'], through: { attributes: [] } },
      ],
    });

    res.json(updated);
  } catch (error) {
    console.error('Errore nell\'aggiornamento issue:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}
