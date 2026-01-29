import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import dotenv from 'dotenv';

dotenv.config();

if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
  console.warn("⚠️ ATTENZIONE: Credenziali Cloudinary mancanti nel file .env!");
  console.warn("L'upload delle immagini potrebbe causare errori o blocchi.");
}

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'bugboard_issues', // Cartella su Cloudinary
    allowed_formats: ['jpg', 'png', 'jpeg', 'gif'],
  },
});

export { cloudinary, storage };
