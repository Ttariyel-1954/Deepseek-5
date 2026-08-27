/**
 * userModel — auth.users cədvəli üçün model qatı
 */
const db = require('../config/db');

async function findByUsernameOrEmail(usernameOrEmail) {
  const { rows } = await db.query(
    `SELECT * FROM auth.users WHERE username = $1 OR email = $1`,
    [usernameOrEmail]
  );
  return rows[0] || null;
}

async function findById(user_id) {
  const { rows } = await db.query(
    `SELECT user_id, username, email, full_name, role, is_active, last_login, created_at, updated_at
     FROM auth.users WHERE user_id = $1`,
    [user_id]
  );
  return rows[0] || null;
}

async function createUser({ username, email, password_hash, full_name, role }) {
  const { rows } = await db.query(
    `INSERT INTO auth.users (username, email, password_hash, full_name, role)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING user_id, username, email, full_name, role, is_active, created_at, updated_at`,
    [username, email, password_hash, full_name || null, role || 'istifadeci']
  );
  return rows[0];
}

async function updateLastLogin(user_id) {
  const { rows } = await db.query(
    `UPDATE auth.users SET last_login = NOW() WHERE user_id = $1 RETURNING user_id, last_login`,
    [user_id]
  );
  return rows[0] || null;
}

async function listUsers() {
  const { rows } = await db.query(
    `SELECT user_id, username, email, full_name, role, is_active, last_login, created_at
     FROM auth.users ORDER BY user_id`
  );
  return rows;
}

module.exports = { findByUsernameOrEmail, findById, createUser, updateLastLogin, listUsers };
