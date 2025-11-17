// middleware/isAdmin.js
export function isAdmin(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ error: 'Utente non autenticato' });
  }
  
  if (req.user.role !== 'ADMIN') {
    return res.status(403).json({ error: 'Accesso negato: solo amministratori' });
  }
  
  next();
}
