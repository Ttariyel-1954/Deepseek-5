const isciModel = require('../models/isciModel');

async function getIsciler(req, res, next) {
  try {
    const items = await isciModel.getIsciler(req.query);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function getIsci(req, res, next) {
  try {
    const item = await isciModel.getIsci(req.params.id);
    if (!item) return res.status(404).json({ error: 'İşçi tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function createIsci(req, res, next) {
  try {
    const item = await isciModel.createIsci(req.body);
    return res.status(201).json(item);
  } catch (err) {
    return next(err);
  }
}

async function updateIsci(req, res, next) {
  try {
    const item = await isciModel.updateIsci(req.params.id, req.body);
    if (!item) return res.status(404).json({ error: 'İşçi tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function deleteIsci(req, res, next) {
  try {
    const item = await isciModel.deleteIsci(req.params.id);
    if (!item) return res.status(404).json({ error: 'İşçi tapılmadı' });
    return res.json({ message: 'İşçi passiv edildi', isci: item });
  } catch (err) {
    return next(err);
  }
}

async function getVezifeler(req, res, next) {
  try {
    const items = await isciModel.getVezifeler();
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

module.exports = { getIsciler, getIsci, createIsci, updateIsci, deleteIsci, getVezifeler };
