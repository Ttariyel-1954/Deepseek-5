jest.mock('../../src/config/db', () => ({
  query: jest.fn(),
  getClient: jest.fn(),
  pool: {},
}));
const db = require('../../src/config/db');
const layiheModel = require('../../src/models/layiheModel');

describe('layiheModel (unit — DB mock)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('getLayiheler — JOIN-li SQL icra edir və sətirləri qaytarır', async () => {
    db.query.mockResolvedValue({ rows: [{ layihe_id: 1, ad: 'Test layihə' }] });

    const rows = await layiheModel.getLayiheler();

    expect(rows).toEqual([{ layihe_id: 1, ad: 'Test layihə' }]);
    expect(db.query).toHaveBeenCalledTimes(1);
    const sql = db.query.mock.calls[0][0];
    expect(sql).toContain('layihe.layihe');
    expect(sql).toContain('ref.muessise');
    expect(sql).toContain('silinib = FALSE');
  });

  test('createLayihe — INSERT icra edir və yaradılmış sətri qaytarır', async () => {
    db.query.mockResolvedValue({ rows: [{ layihe_id: 5, ad: 'Yeni layihə' }] });

    const row = await layiheModel.createLayihe({ muessise_id: 1, is_novu_id: 2, ad: 'Yeni layihə' });

    expect(row.layihe_id).toBe(5);
    expect(db.query).toHaveBeenCalledTimes(1);
    const sql = db.query.mock.calls[0][0];
    expect(sql).toContain('INSERT INTO layihe.layihe');
    // Params: muessise_id, is_novu_id, status_id(default), seher_id, kod, ad, ...
    const params = db.query.mock.calls[0][1];
    expect(params[0]).toBe(1);
    expect(params[1]).toBe(2);
    expect(params[5]).toBe('Yeni layihə');
  });
});
