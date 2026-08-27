const muqavileModel = require('../models/muqavileModel');

async function getMuqavileler(req, res, next) {
  try {
    const items = await muqavileModel.getMuqavileler(req.query);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function getMuqavile(req, res, next) {
  try {
    const item = await muqavileModel.getMuqavile(req.params.id);
    if (!item) return res.status(404).json({ error: 'Müqavilə tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function createMuqavile(req, res, next) {
  try {
    const item = await muqavileModel.createMuqavile(req.body);
    return res.status(201).json(item);
  } catch (err) {
    return next(err);
  }
}

async function updateMuqavile(req, res, next) {
  try {
    const item = await muqavileModel.updateMuqavile(req.params.id, req.body);
    if (!item) return res.status(404).json({ error: 'Müqavilə tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function deleteMuqavile(req, res, next) {
  try {
    const item = await muqavileModel.deleteMuqavile(req.params.id);
    if (!item) return res.status(404).json({ error: 'Müqavilə tapılmadı' });
    return res.json({ message: 'Müqavilə deaktiv edildi', muqavile: item });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getMuqavileler, getMuqavile, createMuqavile, updateMuqavile, deleteMuqavile };
