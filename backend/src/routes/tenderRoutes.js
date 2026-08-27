const express = require('express');
const router = express.Router();
const tenderController = require('../controllers/tenderController');
const { authenticate } = require('../middlewares/auth');
const { tenderValidator, validate } = require('../middlewares/validator');

// İştirakçılar (tender id üzrə)
router.get('/:id/istirakciler', authenticate, tenderController.getIstirakciler);
router.post('/:id/istirakciler', authenticate, tenderController.createIstirakci);
router.put('/:id/istirakciler/:istirakciId', authenticate, tenderController.updateIstirakci);
router.delete('/:id/istirakciler/:istirakciId', authenticate, tenderController.deleteIstirakci);

router.get('/', authenticate, tenderController.getTenderler);
router.get('/:id', authenticate, tenderController.getTender);
router.post('/', authenticate, tenderValidator, validate, tenderController.createTender);
router.put('/:id', authenticate, tenderController.updateTender);
router.delete('/:id', authenticate, tenderController.deleteTender);

module.exports = router;
