import { DataTypes } from 'sequelize';
import { database } from './Database.js';

const IssueTag = database.define('IssueTag', {
  issueId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
  },
  tagId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
  },
}, {
  tableName: 'IssueTags',
  timestamps: false,
});

export default IssueTag;