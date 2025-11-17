import { Sequelize } from "sequelize";
import dotenv from "dotenv";

dotenv.config();

export const database = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: process.env.DB_DIALECT,
    logging: false,
  }
);

export const connectDatabase = async () => {
    try {
        await database.authenticate();  // verifica la connessione al database 
                                        // se i parametri sono corretti e se il db risponde
        console.log("Database connected successfully");
        
        // importo le relazioni dei modelli dopo la definizione e connessione del database
        await import('./Relations.js');
        
        // sincronizza i modelli con il database
        await database.sync({ alter: true }); // aggiornamento dei modelli esistenti
        console.log("Database synchronized");
    } catch (error) {
        console.error("Unable to connect to the database:", error);
        process.exit(1);
    }
};
