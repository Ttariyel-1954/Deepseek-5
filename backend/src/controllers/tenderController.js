const tenderModel = require('../models/tenderModel');

async function getTenderler(req, res, next) {
  try {
    const items = await tenderModel.getTenderler(req.query);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function getTender(req, res, next) {
  try {
    const item = await tenderModel.getTender(req.params.id);
    if (!item) return res.status(404).json({ error: 'Tender tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function createTender(req, res, next) {
  try {
    const item = await tenderModel.createTender(req.body);
    return res.status(201).json(item);
  } catch (err) {
    return next(err);
  }
}

async function updateTender(req, res, next) {
  try {
    const item = await tenderModel.updateTender(req.params.id, req.body);
    if (!item) return res.status(404).json({ error: 'Tender tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function deleteTender(req, res, next) {
  try {
    const item = await tenderModel.deleteTender(req.params.id);
    if (!item) return res.status(404).json({ error: 'Tender tapılmadı' });
    return res.json({ message: 'Tender silindi', tender: item });
  } catch (err) {
    return next(err);
  }
}

// ============================================================
// İŞTİRAKÇILAR
// ============================================================
async function getIstirakciler(req, res, next) {
  try {
    const items = await tenderModel.getIstirakciler(req.params.id);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function createIstirakci(req, res, next) {
  try {
    const item = await tenderModel.createIstirakci(req.params.id, req.body);
    return res.status(201).json(item);
  } catch (err) {
    return next(err);
  }
}

async function updateIstirakci(req, res, next) {
  try {
    const item = await tenderModel.updateIstirakci(req.params.istirakciId, req.body);
    if (!item) return res.status(404).json({ error: 'İştirakçı tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

async function deleteIstirakci(req, res, next) {
  try {
    const item = await tenderModel.deleteIstirakci(req.params.istirakciId);
    if (!item) return res.status(404).json({ error: 'İştirakçı tapılmadı' });
    return res.json({ message: 'İştirakçı silindi', istirakci: item });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getTenderler, getTender, createTender, updateTender, deleteTender,
  getIstirakciler, createIstirakci, updateIstirakci, deleteIstirakci,
};
