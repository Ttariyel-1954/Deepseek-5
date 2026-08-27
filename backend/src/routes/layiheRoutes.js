const express = require('express');
const router = express.Router();
const layiheController = require('../controllers/layiheController');
const { authenticate } = require('../middlewares/auth');
const { layiheValidator, validate } = require('../middlewares/validator');

router.get('/', authenticate, layiheController.getLayiheler);
router.get('/:id/merheleler', authenticate, layiheController.getMerheleler);
router.get('/:id', authenticate, layiheController.getLayihe);
router.post('/', authenticate, layiheValidator, validate, layiheController.createLayihe);
router.put('/:id', authenticate, layiheController.updateLayihe);
router.delete('/:id', authenticate, layiheController.deleteLayihe);

module.exports = router;
