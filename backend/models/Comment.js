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
  issueId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Issues',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  authorId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
}, {
  tableName: 'Comments',
  timestamps: true,
});

export default Comment;