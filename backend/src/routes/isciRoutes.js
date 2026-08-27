const express = require('express');
const router = express.Router();
const isciController = require('../controllers/isciController');
const { authenticate } = require('../middlewares/auth');
const { isciValidator, validate } = require('../middlewares/validator');

router.get('/vezifeler', authenticate, isciController.getVezifeler);
router.get('/', authenticate, isciController.getIsciler);
router.get('/:id', authenticate, isciController.getIsci);
router.post('/', authenticate, isciValidator, validate, isciController.createIsci);
router.put('/:id', authenticate, isciController.updateIsci);
router.delete('/:id', authenticate, isciController.deleteIsci);

module.exports = router;
