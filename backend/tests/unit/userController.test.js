import { jest } from '@jest/globals';

const mockUser = {
  findOne: jest.fn(),
  create: jest.fn(),
  findByPk: jest.fn(),
};

jest.unstable_mockModule('../../models/User.js', () => ({ default: mockUser }));
jest.unstable_mockModule('bcrypt', () => ({
  default: {
    hash: jest.fn(),
  }
}));

const { createUser } = await import('../../controllers/userController.js');
const bcrypt = (await import('bcrypt')).default;

describe('User Controller', () => {
  let req, res;

  beforeEach(() => {
    req = { body: {} };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    jest.clearAllMocks();
  });

  describe('createUser', () => {
    it('should return 400 if email already exists', async () => {
      req.body = { email: 'test@test.com', password: 'password' };
      mockUser.findOne.mockResolvedValue({ id: 1 }); // Existing user

      await createUser(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: 'Email già in uso' });
    });

    it('should create user successfully', async () => {
      req.body = { email: 'new@test.com', password: 'password', role: 'USER' };
      mockUser.findOne.mockResolvedValue(null);
      bcrypt.hash.mockResolvedValue('hashedPassword');
      mockUser.create.mockResolvedValue({ id: 1, email: 'new@test.com' });

      await createUser(req, res);

      expect(mockUser.create).toHaveBeenCalledWith(expect.objectContaining({
        email: 'new@test.com',
        passwordHash: 'hashedPassword',
        role: 'USER'
      }));
      expect(res.status).toHaveBeenCalledWith(201);
    });
  });
});
