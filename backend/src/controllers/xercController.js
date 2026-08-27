const xercModel = require('../models/xercModel');

async function getXercler(req, res, next) {
  try {
    const items = await xercModel.getXercler(req.query);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function getXerc(req, res, next) {
  try {
    const item = await xercModel.getXerc(req.params.id);
    if (!item) return res.status(404).json({ error: 'Xərc tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function createXerc(req, res, next) {
  try {
    const item = await xercModel.createXerc({ ...req.body, created_by: req.user ? req.user.user_id : null });
    return res.status(201).json(item);
  } catch (err) {
    return next(err);
  }
}

async function updateXerc(req, res, next) {
  try {
    const item = await xercModel.updateXerc(req.params.id, req.body);
    if (!item) return res.status(404).json({ error: 'Xərc tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function deleteXerc(req, res, next) {
  try {
    const item = await xercModel.deleteXerc(req.params.id);
    if (!item) return res.status(404).json({ error: 'Xərc tapılmadı' });
    return res.json({ message: 'Xərc silindi', xerc: item });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getXercler, getXerc, createXerc, updateXerc, deleteXerc };
