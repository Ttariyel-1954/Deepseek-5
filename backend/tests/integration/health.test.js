const request = require('supertest');
const app = require('../../src/app');
const db = require('../../src/config/db');

describe('Health API (integration)', () => {
  afterAll(async () => {
    await db.pool.end();
  });

  test('GET /api/health → 200 və status ok', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.db).toBe('ok');
  });

  test('GET /api/unknown → 404', async () => {
    const res = await request(app).get('/api/unknown-endpoint');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeDefined();
  });
});
