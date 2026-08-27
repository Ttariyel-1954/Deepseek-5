const express = require('express');
const router = express.Router();
const muqavileController = require('../controllers/muqavileController');
const { authenticate } = require('../middlewares/auth');
const { muqavileValidator, validate } = require('../middlewares/validator');

router.get('/', authenticate, muqavileController.getMuqavileler);
router.get('/:id', authenticate, muqavileController.getMuqavile);
router.post('/', authenticate, muqavileValidator, validate, muqavileController.createMuqavile);
router.put('/:id', authenticate, muqavileController.updateMuqavile);
router.delete('/:id', authenticate, muqavileController.deleteMuqavile);

module.exports = router;
