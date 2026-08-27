const userModel = require('../models/userModel');
const { signToken, hashPassword, comparePassword } = require('../config/auth');

async function register(req, res, next) {
  try {
    const { username, email, password, full_name, role } = req.body;

    const existing = await userModel.findByUsernameOrEmail(username);
    if (existing) {
      return res.status(409).json({ error: 'Bu istifadəçi adı və ya e-poçt artıq istifadə olunur' });
    }

    const password_hash = await hashPassword(password);
    const user = await userModel.createUser({ username, email, password_hash, full_name, role });

    const token = signToken({ user_id: user.user_id, username: user.username, role: user.role });
    return res.status(201).json({ token, user });
  } catch (err) {
    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const { usernameOrEmail, password } = req.body;

    const user = await userModel.findByUsernameOrEmail(usernameOrEmail);
    if (!user || !user.is_active) {
      return res.status(401).json({ error: 'İstifadəçi tapılmadı və ya hesab deaktivdir' });
    }

    const ok = await comparePassword(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ error: 'Şifrə yanlışdır' });
    }

    await userModel.updateLastLogin(user.user_id);

    const token = signToken({ user_id: user.user_id, username: user.username, role: user.role });
    return res.json({
      token,
      user: {
        user_id: user.user_id,
        username: user.username,
        email: user.email,
        full_name: user.full_name,
        role: user.role,
      },
    });
  } catch (err) {
    return next(err);
  }
}

async function profile(req, res, next) {
  try {
    const user = await userModel.findById(req.user.user_id);
    if (!user) {
      return res.status(404).json({ error: 'İstifadəçi tapılmadı' });
    }
    return res.json({ user });
  } catch (err) {
    return next(err);
  }
}

module.exports = { register, login, profile };
