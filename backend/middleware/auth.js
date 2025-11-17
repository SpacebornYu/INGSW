// middleware/auth.js
import jwt from 'jsonwebtoken';

export function auth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Token mancante o non valido' });
    }

    const token = authHeader.substring(7); // rimuovi "Bearer "
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Attacca i dati utente alla request
    req.user = {
      id: decoded.id,
      email: decoded.email,
      role: decoded.role,
    };
    
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Token non valido o scaduto' });
  }
}
