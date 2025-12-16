import { DataTypes } from 'sequelize';
import { database } from './Database.js';

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
    type: DataTypes.ENUM('VERY LOW', 'LOW', 'MEDIUM', 'HIGH', 'VERY HIGH'),
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('TODO', 'IN_CORSO', 'COMPLETATA'),
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