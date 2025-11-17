import { DataTypes } from 'sequelize';
import { database } from './database.js';

const Comment = database.define('Comment', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
}, {
  tableName: 'Comments',
  timestamps: true,
});

export default Comment;