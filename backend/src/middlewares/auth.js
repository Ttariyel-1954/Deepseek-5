const { verifyToken } = require('../config/auth');

/**
 * JWT əsaslı autentifikasiya middleware-i
 * Authorization: Bearer <token> başlığını yoxlayır
 */
function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: 'Token tələb olunur' });
  }

  try {
    const decoded = verifyToken(token);
    req.user = {
      user_id: decoded.user_id,
      username: decoded.username,
      role: decoded.role,
    };
    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Yanlış və ya vaxtı keçmiş token' });
  }
}

/**
 * Rol əsaslı icazə middleware-i
 * @param {...string} roles - icazə verilən rollar
 */
function authorize(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Token tələb olunur' });
    }
    if (roles.includes(req.user.role)) {
      return next();
    }
    return res.status(403).json({ error: 'Bu əməliyyat üçün icazəniz yoxdur' });
  };
}

module.exports = { authenticate, authorize };
