const express = require('express');
const router = express.Router();
const odenisController = require('../controllers/odenisController');
const { authenticate } = require('../middlewares/auth');
const { odenisValidator, validate } = require('../middlewares/validator');

router.get('/', authenticate, odenisController.getOdenisler);
router.get('/:id', authenticate, odenisController.getOdenis);
router.post('/', authenticate, odenisValidator, validate, odenisController.createOdenis);
router.put('/:id', authenticate, odenisController.updateOdenis);
router.delete('/:id', authenticate, odenisController.deleteOdenis);

module.exports = router;
