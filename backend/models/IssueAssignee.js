import { DataTypes } from 'sequelize';
import { database } from './database.js';

const IssueAssignee = database.define('IssueAssignee', {
  issueId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
  },
}, {
  tableName: 'IssueAssignees',
  timestamps: false,
});

export default IssueAssignee;