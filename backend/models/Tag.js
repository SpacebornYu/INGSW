import { DataTypes } from 'sequelize';
import { database } from './database.js';

const Tag = database.define('Tag', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  name: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true,
  },
}, {
  tableName: 'Tags',
  timestamps: true,
});

export default Tag;