import { DataTypes } from 'sequelize';
import { database } from './database.js';

const Issue = database.define('Issue', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  type: {
    type: DataTypes.ENUM('QUESTION', 'BUG', 'DOCUMENTATION', 'FEATURE'),
    allowNull: false,
  },
  priority: {
    type: DataTypes.ENUM('LOW', 'MEDIUM', 'HIGH', 'URGENT'),
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('TODO', 'IN_PROGRESS', 'DONE'),
    allowNull: false,
    defaultValue: 'TODO',
  },
  imageUrl: {
    type: DataTypes.TEXT,
    allowNull: true, // URL Cloudinary
  },
  creatorId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
}, {
  tableName: 'Issues',
  timestamps: true,
});

export default Issue;