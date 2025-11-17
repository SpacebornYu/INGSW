// services/initAdmin.js
import bcrypt from 'bcrypt';
import User from '../models/User.js';

export async function ensureDefaultAdmin() {
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@example.com';
  const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';

  try {
    // Controlla se esiste già un admin con questa email
    const existing = await User.findOne({ where: { email: adminEmail } });
    
    if (existing) {
      console.log(`Admin di default già presente (${adminEmail})`);
      return;
    }

    const passwordHash = await bcrypt.hash(adminPassword, 10);

    await User.create({
      email: adminEmail,
      passwordHash,
      role: 'ADMIN',
    });

    console.log(`✅ Admin di default creato con email: ${adminEmail}`);
    console.log(`   Password: ${adminPassword}`);
    console.log(`   Ricorda di cambiare la password in produzione!`);
  } catch (error) {
    console.error('Errore nella creazione dell\'admin di default:', error);
  }
}
