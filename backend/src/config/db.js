const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME || 'deepseek_erp_v6',
  user: process.env.DB_USER || 'deepseek_admin',
  password: process.env.DB_PASSWORD || 'Deepseek2026',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('PostgreSQL pool xətası:', err.message);
});

/**
 * SQL sorğusunu icra edir
 * @param {string} text - SQL mətni
 * @param {Array} [params] - parametrlər
 * @returns {Promise<import('pg').QueryResult>}
 */
async function query(text, params) {
  return pool.query(text, params);
}

/**
 * Transaction üçün client əldə edir
 * @returns {Promise<import('pg').PoolClient>}
 */
async function getClient() {
  return pool.connect();
}

module.exports = { pool, query, getClient };
