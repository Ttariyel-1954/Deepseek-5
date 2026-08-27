const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const JWT_SECRET = process.env.JWT_SECRET || 'deepseek_5_dev_secret';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * JWT token imzalayır
 * @param {object} payload - { user_id, username, role, ... }
 * @returns {string}
 */
function signToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

/**
 * JWT tokeni yoxlayır
 * @param {string} token
 * @returns {object} decoded payload
 */
function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

/**
 * Şifrəni bcrypt ilə heşləyir
 * @param {string} plain
 * @returns {Promise<string>}
 */
async function hashPassword(plain) {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(plain, salt);
}

/**
 * Düz mətn şifrəni heşlə müqayisə edir
 * @param {string} plain
 * @param {string} hash
 * @returns {Promise<boolean>}
 */
function comparePassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}

module.exports = { signToken, verifyToken, hashPassword, comparePassword, JWT_SECRET };
