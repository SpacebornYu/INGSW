import express from "express";
import cors from "cors";
import { connectDatabase } from "./models/database.js";
import { ensureDefaultAdmin } from "./services/initAdmin.js";

// Import routes
import authRoutes from "./routes/authRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import issueRoutes from "./routes/issueRoutes.js";
import commentRoutes from "./routes/commentRoutes.js";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());

app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'BugBoard26 backend' });
});

// Mount routes
app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/issues', issueRoutes);
app.use('/', commentRoutes);

// Connessione al database e avvio server
const startServer = async () => {
  try {
    await connectDatabase();
    console.log('Connesso a PostgreSQL con Sequelize ✅');
    
    await ensureDefaultAdmin();
    
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`BugBoard26 backend in ascolto sulla porta ${PORT}`);
    });
  } catch (error) {
    console.error("Errore durante l'avvio del server:", error);
    process.exit(1);
  }
};

// avvio del server
startServer();

