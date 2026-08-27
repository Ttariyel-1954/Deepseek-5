const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { authenticate } = require('../middlewares/auth');
const { teyinatValidator, aiTesdiqValidator, validate } = require('../middlewares/validator');

// Modellər və agentlər
router.get('/modeller', authenticate, aiController.getModels);
router.get('/agentler', authenticate, aiController.getAgents);

// Təyinatlar
router.get('/teyinatlar', authenticate, aiController.getTeyinatlar);
router.post('/teyinatlar', authenticate, teyinatValidator, validate, aiController.createTeyinat);
router.post('/teyinatlar/:id/icra', authenticate, aiController.icraTeyinat);

// Qərarlar
router.get('/qerarlar', authenticate, aiController.getQerarlar);
router.post('/qerarlar/:id/tesdiq', authenticate, aiTesdiqValidator, validate, aiController.tesdiqleQerar);
router.post('/qerarlar/:id/redd', authenticate, aiTesdiqValidator, validate, aiController.reddEtQerar);

// Proqnozlar
router.get('/proqnozlar', authenticate, aiController.getProqnozlar);

// Mesajlar
router.get('/mesajlar', authenticate, aiController.getMesajlar);
router.post('/mesajlar/:id/oxunub', authenticate, aiController.oxunubMesaj);

// Loqlar
router.get('/loglar', authenticate, aiController.getLoglar);

module.exports = router;
