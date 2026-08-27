const layiheModel = require('../models/layiheModel');

async function getLayiheler(req, res, next) {
  try {
    const items = await layiheModel.getLayiheler(req.query);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function getLayihe(req, res, next) {
  try {
    const item = await layiheModel.getLayihe(req.params.id);
    if (!item) return res.status(404).json({ error: 'Layihə tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function createLayihe(req, res, next) {
  try {
    const item = await layiheModel.createLayihe({ ...req.body, created_by: req.user ? req.user.user_id : null });
    return res.status(201).json(item);
  } catch (err) {
    return next(err);
  }
}

async function updateLayihe(req, res, next) {
  try {
    const item = await layiheModel.updateLayihe(req.params.id, req.body);
    if (!item) return res.status(404).json({ error: 'Layihə tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function deleteLayihe(req, res, next) {
  try {
    const item = await layiheModel.deleteLayihe(req.params.id);
    if (!item) return res.status(404).json({ error: 'Layihə tapılmadı' });
    return res.json({ message: 'Layihə silindi', layihe: item });
  } catch (err) {
    return next(err);
  }
}

async function getMerheleler(req, res, next) {
  try {
    const items = await layiheModel.getMerheleler(req.params.id);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

module.exports = { getLayiheler, getLayihe, createLayihe, updateLayihe, deleteLayihe, getMerheleler };
