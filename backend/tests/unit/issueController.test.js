import { jest } from '@jest/globals';

// Mock dependencies
const mockIssue = {
  create: jest.fn(),
  findByPk: jest.fn(),
  findAll: jest.fn(),
};
const mockUser = {};
const mockTag = {
  findOrCreate: jest.fn(),
};
const mockComment = {};

jest.unstable_mockModule('../../models/Issue.js', () => ({ default: mockIssue }));
jest.unstable_mockModule('../../models/User.js', () => ({ default: mockUser }));
jest.unstable_mockModule('../../models/Tag.js', () => ({ default: mockTag }));
jest.unstable_mockModule('../../models/Comment.js', () => ({ default: mockComment }));
jest.unstable_mockModule('sequelize', () => ({
  Op: {
    or: Symbol('or'),
    iLike: Symbol('iLike'),
  }
}));

const { createIssue, getIssues } = await import('../../controllers/issueController.js');

describe('Issue Controller', () => {
  let req, res;

  beforeEach(() => {
    req = {
      body: {},
      user: { id: 1 },
      file: null,
      files: []
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    jest.clearAllMocks();
  });

  describe('createIssue', () => {
    it('should return 400 if title is missing', async () => {
      req.body = { description: 'desc', type: 'BUG' };
      
      await createIssue(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: 'Titolo, descrizione, tipo e priorità sono obbligatori' });
    });

    it('should create an issue successfully', async () => {
      req.body = { title: 'Title', description: 'Desc', type: 'BUG', priority: 'HIGH' };
      const mockCreatedIssue = { id: 1, addTags: jest.fn() };
      mockIssue.create.mockResolvedValue(mockCreatedIssue);
      mockIssue.findByPk.mockResolvedValue(mockCreatedIssue);

      await createIssue(req, res);

      expect(mockIssue.create).toHaveBeenCalledWith(expect.objectContaining({
        title: 'Title',
        description: 'Desc',
        type: 'BUG',
        priority: 'HIGH',
        creatorId: 1
      }));
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(mockCreatedIssue);
    });
  });

  describe('getIssues', () => {
    it('should filter by status', async () => {
      req.query = { status: 'TODO' };
      mockIssue.findAll.mockResolvedValue([]);

      await getIssues(req, res);

      expect(mockIssue.findAll).toHaveBeenCalledWith(expect.objectContaining({
        where: expect.objectContaining({ status: 'TODO' })
      }));
      expect(res.json).toHaveBeenCalledWith([]);
    });

    it('should filter by search text', async () => {
      req.query = { search: 'bug' };
      mockIssue.findAll.mockResolvedValue([]);

      await getIssues(req, res);

      // Verifica che venga usato Op.or per cercare nel titolo o descrizione
      const callArgs = mockIssue.findAll.mock.calls[0][0];
      const whereClause = callArgs.where;
      const opOr = Object.getOwnPropertySymbols(whereClause)[0];
      
      expect(whereClause[opOr]).toBeDefined();
      expect(res.json).toHaveBeenCalledWith([]);
    });
  });
});
