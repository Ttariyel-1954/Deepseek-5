jest.mock('../../src/models/layiheModel');
const layiheModel = require('../../src/models/layiheModel');
const layiheController = require('../../src/controllers/layiheController');

describe('layiheController (unit)', () => {
  let req, res, next;

  beforeEach(() => {
    req = { body: {}, params: {}, query: {}, user: { user_id: 1 } };
    res = { status: jest.fn().mockReturnThis(), json: jest.fn().mockReturnThis() };
    next = jest.fn();
    jest.clearAllMocks();
  });

  test('getLayiheler — siyahını JSON olaraq qaytarır', async () => {
    const fakeList = [{ layihe_id: 1, ad: 'Məktəb təmiri' }, { layihe_id: 2, ad: 'Bağça təmiri' }];
    layiheModel.getLayiheler.mockResolvedValue(fakeList);

    await layiheController.getLayiheler(req, res, next);

    expect(layiheModel.getLayiheler).toHaveBeenCalledWith(req.query);
    expect(res.json).toHaveBeenCalledWith(fakeList);
    expect(next).not.toHaveBeenCalled();
  });

  test('getLayihe — tək layihəni qaytarır', async () => {
    layiheModel.getLayihe.mockResolvedValue({ layihe_id: 2, ad: 'Bağça təmiri' });
    req.params.id = '2';

    await layiheController.getLayihe(req, res, next);

    expect(layiheModel.getLayihe).toHaveBeenCalledWith('2');
    expect(res.json).toHaveBeenCalledWith({ layihe_id: 2, ad: 'Bağça təmiri' });
    expect(next).not.toHaveBeenCalled();
  });

  test('createLayihe — yeni layihə yaradır və 201 qaytarır', async () => {
    layiheModel.createLayihe.mockResolvedValue({ layihe_id: 3, ad: 'Yeni layihə' });
    req.body = { ad: 'Yeni layihə', muessise_id: 1, is_novu_id: 1 };

    await layiheController.createLayihe(req, res, next);

    expect(layiheModel.createLayihe).toHaveBeenCalledTimes(1);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({ layihe_id: 3, ad: 'Yeni layihə' });
    expect(next).not.toHaveBeenCalled();
  });
});
