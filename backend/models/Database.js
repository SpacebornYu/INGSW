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
    let retries = 5;
    while (retries > 0) {
        try {
            await database.authenticate();
            console.log("Database connected successfully");
            
            await import('./Relations.js');
            await database.sync({ alter: true });
            console.log("Database synchronized");
            return; // Success
        } catch (error) {
            console.log(`Database connection failed, retrying in 5 seconds... (${retries} retries left)`);
            console.error(error.message);
            retries -= 1;
            await new Promise(res => setTimeout(res, 5000));
        }
    }
    throw new Error("Could not connect to database after multiple retries");
};

