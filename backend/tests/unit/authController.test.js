const bcrypt = require('bcryptjs');

jest.mock('../../src/models/userModel');
const userModel = require('../../src/models/userModel');
const authController = require('../../src/controllers/authController');

describe('authController (unit)', () => {
  let req, res, next;

  beforeEach(() => {
    req = { body: {}, params: {}, user: {} };
    res = { status: jest.fn().mockReturnThis(), json: jest.fn().mockReturnThis() };
    next = jest.fn();
    jest.clearAllMocks();
  });

  test('register — yeni istifadəçi yaradır, 201 və token qaytarır', async () => {
    userModel.findByUsernameOrEmail.mockResolvedValue(null);
    userModel.createUser.mockResolvedValue({
      user_id: 1,
      username: 'testuser',
      email: 'test@test.az',
      role: 'istifadeci',
    });

    req.body = { username: 'testuser', email: 'test@test.az', password: 'password123', full_name: 'Test User' };

    await authController.register(req, res, next);

    expect(userModel.findByUsernameOrEmail).toHaveBeenCalledWith('testuser');
    expect(userModel.createUser).toHaveBeenCalledTimes(1);
    expect(res.status).toHaveBeenCalledWith(201);
    const payload = res.json.mock.calls[0][0];
    expect(payload.token).toBeDefined();
    expect(payload.user.username).toBe('testuser');
    expect(next).not.toHaveBeenCalled();
  });

  test('login — düzgün şifrə ilə token qaytarır', async () => {
    const password_hash = bcrypt.hashSync('admin123', 10);
    userModel.findByUsernameOrEmail.mockResolvedValue({
      user_id: 1,
      username: 'admin',
      email: 'admin@deepseek5.az',
      password_hash,
      role: 'admin',
      is_active: true,
    });
    userModel.updateLastLogin.mockResolvedValue({ user_id: 1, last_login: new Date() });

    req.body = { usernameOrEmail: 'admin', password: 'admin123' };

    await authController.login(req, res, next);

    expect(userModel.updateLastLogin).toHaveBeenCalledWith(1);
    expect(res.json).toHaveBeenCalledTimes(1);
    const payload = res.json.mock.calls[0][0];
    expect(payload.token).toBeDefined();
    expect(payload.user.username).toBe('admin');
    expect(next).not.toHaveBeenCalled();
  });

  test('profile — cari istifadəçini qaytarır', async () => {
    userModel.findById.mockResolvedValue({
      user_id: 1,
      username: 'admin',
      email: 'admin@deepseek5.az',
      role: 'admin',
    });

    req.user = { user_id: 1 };

    await authController.profile(req, res, next);

    expect(userModel.findById).toHaveBeenCalledWith(1);
    expect(res.json).toHaveBeenCalledTimes(1);
    expect(res.json.mock.calls[0][0].user.username).toBe('admin');
    expect(next).not.toHaveBeenCalled();
  });
});
