// controllers/userController.js
import bcrypt from 'bcrypt';
import User from '../models/User.js';

// GET /users/me - profilo utente corrente
export async function getMe(req, res) {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: ['id', 'email', 'role', 'createdAt'],
    });

    if (!user) {
      return res.status(404).json({ error: 'Utente non trovato' });
    }

    res.json(user);
  } catch (error) {
    console.error('Errore nel recupero profilo:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}

// POST /admin/users - crea nuovo utente (solo admin)
export async function createUser(req, res) {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email e password sono obbligatori' });
    }

    // Validazione formato email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Formato email non valido' });
    }

    if (role && !['ADMIN', 'USER'].includes(role)) {
      return res.status(400).json({ error: 'Ruolo non valido' });
    }

    // Verifica che l'email non sia già usata
    const existing = await User.findOne({ where: { email } });
    if (existing) {
      return res.status(400).json({ error: 'Email già in uso' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    const user = await User.create({
      email,
      passwordHash,
      role: role || 'USER',
    });

    res.status(201).json({
      id: user.id,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    });
  } catch (error) {
    console.error('Errore nella creazione utente:', error);
    res.status(500).json({ error: 'Errore del server' });
  }
}
