const odenisModel = require('../models/odenisModel');

async function getOdenisler(req, res, next) {
  try {
    const items = await odenisModel.getOdenisler(req.query);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function getOdenis(req, res, next) {
  try {
    const item = await odenisModel.getOdenis(req.params.id);
    if (!item) return res.status(404).json({ error: 'Ödəniş tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function createOdenis(req, res, next) {
  try {
    const item = await odenisModel.createOdenis({ ...req.body, created_by: req.user ? req.user.user_id : null });
    return res.status(201).json(item);
  } catch (err) {
    return next(err);
  }
}

async function updateOdenis(req, res, next) {
  try {
    const item = await odenisModel.updateOdenis(req.params.id, req.body);
    if (!item) return res.status(404).json({ error: 'Ödəniş tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function deleteOdenis(req, res, next) {
  try {
    const item = await odenisModel.deleteOdenis(req.params.id);
    if (!item) return res.status(404).json({ error: 'Ödəniş tapılmadı' });
    return res.json({ message: 'Ödəniş silindi', odenis: item });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getOdenisler, getOdenis, createOdenis, updateOdenis, deleteOdenis };
