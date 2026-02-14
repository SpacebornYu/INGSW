// controllers/issueController.js
import { Op } from 'sequelize';
import { database } from '../models/Database.js';
import Issue from '../models/Issue.js';
import User from '../models/User.js';
import Tag from '../models/Tag.js';
import Comment from '../models/Comment.js';

// POST /issues - crea una nuova issue
// backend/controllers/issueController.js

export async function createIssue(req, res) {
  let t;
  try {
    t = await database.transaction();
    let { title, description, type, priority, tags } = req.body;
    
    // Handle images
    let imageUrl = null;
    if (req.files && req.files.length > 0) {
        const urls = req.files.map(f => f.path);
        imageUrl = JSON.stringify(urls);
    } else if (req.file) {
        imageUrl = JSON.stringify([req.file.path]);
    }

    if (!title || !description || !type || !priority) {
      await t.rollback();
      return res.status(400).json({ error: 'Titolo, descrizione, tipo e priorità sono obbligatori' });
    }

    // Validazione Lunghezza
    if (title.length > 100) {
      await t.rollback();
      return res.status(400).json({ error: 'Il titolo non può superare i 100 caratteri' });
    }
    if (description.length > 2000) {
      await t.rollback();
      return res.status(400).json({ error: 'La descrizione non può superare i 2000 caratteri' });
    }

    // Validazione Type
    const validTypes = ['QUESTION', 'BUG', 'DOCUMENTATION', 'FEATURE'];
    if (!validTypes.includes(type)) {
      await t.rollback();
      return res.status(400).json({ error: 'Tipo non valido' });
    }

    // Controllo priorità aggiornato (Allineato con il DB)
    const validPriorities = ['VERY LOW', 'LOW', 'MEDIUM', 'HIGH', 'VERY HIGH'];
    if (!validPriorities.includes(priority)) {
      await t.rollback();
      return res.status(400).json({ error: 'Priorità non valida' });
    }

    // Gestione tag
    if (typeof tags === 'string') {
        try {
            tags = JSON.parse(tags);
        } catch (e) {
            tags = [tags];
        }
    }

    if (tags && Array.isArray(tags) && tags.length > 0) {
      // Normalize tags (trim) and check duplicates
      const normalizedTags = tags.map(t => t.trim());
      const uniqueTags = new Set(normalizedTags);
      
      if (uniqueTags.size !== normalizedTags.length) {
        await t.rollback();
        return res.status(400).json({ error: 'Non sono ammessi tag duplicati' });
      }

      tags = normalizedTags;

      // Validazione lunghezza tag
      for (const tag of tags) {
        if (tag.length > 50) {
          await t.rollback();
          return res.status(400).json({ error: `Il tag "${tag}" supera i 50 caratteri` });
        }
      }
    }

    const issue = await Issue.create({
      title,
      description,
      type,
      priority,
      status: 'TODO',
      creatorId: req.user.id,
      imageUrl: imageUrl,
    }, { transaction: t });

    if (tags && Array.isArray(tags) && tags.length > 0) {
      const tagInstances = await Promise.all(
        tags.map(tagName => 
          Tag.findOrCreate({ where: { name: tagName.trim() }, transaction: t })
            .then(([tag]) => tag)
        )
      );
      await issue.addTags(tagInstances, { transaction: t });
    }

    await t.commit();

    try {
        const issueWithRelations = await Issue.findByPk(issue.id, {
        include: [
            { model: User, as: 'creator', attributes: ['id', 'email'] },
            { model: Tag, as: 'tags', attributes: ['id', 'name'], through: { attributes: [] } },
        ],
        });

        if (!issueWithRelations) {
             console.error('Issue creata ma non trovata dopo il commit.');
             return res.status(201).json(issue); // Fallback: return basic issue
        }

        res.status(201).json(issueWithRelations);
    } catch (fetchError) {
         console.error('Errore nel recupero della issue dopo commit:', fetchError);
         // La issue è stata creata, quindi ritorniamo comunque 201 ma con l'oggetto base
         if (!res.headersSent) {
            res.status(201).json(issue);
         }
    }

  } catch (error) {
    if (t && !t.finished) {
        try {
            await t.rollback();
        } catch (rollbackError) {
            console.error('Errore durante il rollback:', rollbackError);
        }
    }
    
    console.error('Errore nella creazione issue:', error);
    
    if (!res.headersSent) {
        res.status(500).json({ error: 'Errore del server' });
    }
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

    // Validazione filtri per evitare errori DB su ENUM
    const validTypes = ['QUESTION', 'BUG', 'DOCUMENTATION', 'FEATURE'];
    if (type && validTypes.includes(type)) where.type = type;

    const validStatuses = ['TODO', 'IN_CORSO', 'COMPLETATA'];
    if (status && validStatuses.includes(status)) where.status = status;

    const validPriorities = ['VERY LOW', 'LOW', 'MEDIUM', 'HIGH', 'VERY HIGH'];
    if (priority && validPriorities.includes(priority)) where.priority = priority;

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
    if (priority && !['VERY LOW', 'LOW', 'MEDIUM', 'HIGH', 'VERY HIGH'].includes(priority)) {
  return res.status(400).json({ error: 'Priorità non valida' });
}
      issue.priority = priority;
    }
    if (status) {
      if (!['TODO', 'IN_CORSO', 'COMPLETATA'].includes(status)) {
        return res.status(400).json({ error: 'Stato non valido' });
      }
      issue.status = status;
    }

    await issue.save();

    // Aggiorna tag se presenti
    if (tags && Array.isArray(tags)) {
      // Validazione lunghezza tag
      for (const tag of tags) {
        if (tag.length > 50) {
          return res.status(400).json({ error: `Il tag "${tag}" supera i 50 caratteri` });
        }
      }

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
