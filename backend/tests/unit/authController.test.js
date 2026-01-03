import { jest } from '@jest/globals';

const mockUser = {
  findOne: jest.fn(),
};

jest.unstable_mockModule('../../models/User.js', () => ({ default: mockUser }));
jest.unstable_mockModule('bcrypt', () => ({
  default: {
    compare: jest.fn(),
  }
}));
jest.unstable_mockModule('jsonwebtoken', () => ({
  default: {
    sign: jest.fn(),
  }
}));

const { login } = await import('../../controllers/authController.js');
const bcrypt = (await import('bcrypt')).default;
const jwt = (await import('jsonwebtoken')).default;

describe('Auth Controller', () => {
  let req, res;

  beforeEach(() => {
    req = { body: {} };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    jest.clearAllMocks();
    process.env.JWT_SECRET = 'secret';
  });

  describe('login', () => {
    it('should return 400 if email is missing', async () => {
      req.body = { password: 'password' };
      await login(req, res);
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('should return 401 if user not found', async () => {
      req.body = { email: 'test@test.com', password: 'password' };
      mockUser.findOne.mockResolvedValue(null);
      
      await login(req, res);
      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('should return token on success', async () => {
      req.body = { email: 'test@test.com', password: 'password' };
      const user = { id: 1, email: 'test@test.com', passwordHash: 'hash', role: 'USER' };
      mockUser.findOne.mockResolvedValue(user);
      bcrypt.compare.mockResolvedValue(true);
      jwt.sign.mockReturnValue('token');

      await login(req, res);

      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ token: 'token' }));
    });
  });
});
