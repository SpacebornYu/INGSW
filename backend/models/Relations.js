import { database } from './database.js';
import User from './User.js';
import Issue from './Issue.js';
import Comment from './Comment.js';
import Tag from './Tag.js';
import IssueTag from './IssueTag.js';
import IssueAssignee from './IssueAssignee.js';

// Relazioni User <-> Issue (creator)
User.hasMany(Issue, { as: 'createdIssues', foreignKey: 'creatorId' });
Issue.belongsTo(User, { as: 'creator', foreignKey: 'creatorId' });

// Commenti
Issue.hasMany(Comment, { foreignKey: 'issueId' });
Comment.belongsTo(Issue, { foreignKey: 'issueId' });

User.hasMany(Comment, { as: 'comments', foreignKey: 'authorId' });
Comment.belongsTo(User, { as: 'author', foreignKey: 'authorId' });

// Tag (N-N)
Issue.belongsToMany(Tag, {
  through: IssueTag,
  as: 'tags',
  foreignKey: 'issueId',
});
Tag.belongsToMany(Issue, {
  through: IssueTag,
  as: 'issues',
  foreignKey: 'tagId',
});

// Assegnatari (N-N, max 3 gestito nel codice)
Issue.belongsToMany(User, {
  through: IssueAssignee,
  as: 'assignees',
  foreignKey: 'issueId',
});
User.belongsToMany(Issue, {
  through: IssueAssignee,
  as: 'assignedIssues',
  foreignKey: 'userId',
});

export default {
  database,
  User,
  Issue,
  Comment,
  Tag,
  IssueTag,
  IssueAssignee,
};