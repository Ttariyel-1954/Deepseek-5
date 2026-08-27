const express = require('express');
const router = express.Router();
const xercController = require('../controllers/xercController');
const { authenticate } = require('../middlewares/auth');
const { xercValidator, validate } = require('../middlewares/validator');

router.get('/', authenticate, xercController.getXercler);
router.get('/:id', authenticate, xercController.getXerc);
router.post('/', authenticate, xercValidator, validate, xercController.createXerc);
router.put('/:id', authenticate, xercController.updateXerc);
router.delete('/:id', authenticate, xercController.deleteXerc);

module.exports = router;
