const { body, validationResult } = require('express-validator');

// ============================================================
// AUTH VALİDATORLARI
// ============================================================
const registerValidator = [
  body('username')
    .trim()
    .notEmpty().withMessage('İstifadəçi adı tələb olunur')
    .isLength({ min: 3 }).withMessage('İstifadəçi adı ən az 3 simvol olmalıdır'),
  body('email').isEmail().withMessage('Düzgün e-poçt ünvanı daxil edin'),
  body('password')
    .isLength({ min: 6 }).withMessage('Şifrə ən az 6 simvol olmalıdır'),
];

const loginValidator = [
  body('usernameOrEmail').notEmpty().withMessage('İstifadəçi adı və ya e-poçt tələb olunur'),
  body('password').notEmpty().withMessage('Şifrə tələb olunur'),
];

// ============================================================
// CRUD VALİDATORLARI
// ============================================================
const layiheValidator = [
  body('ad').trim().notEmpty().withMessage('Layihə adı tələb olunur'),
  body('muessise_id').isInt().withMessage('Müəssisə ID tələb olunur'),
  body('is_novu_id').isInt().withMessage('İş növü ID tələb olunur'),
  body('plan_budce').optional().isNumeric().withMessage('Plan büdcə ədəd olmalıdır'),
];

const tenderValidator = [
  body('ad').trim().notEmpty().withMessage('Tender adı tələb olunur'),
  body('layihe_id').isInt().withMessage('Layihə ID tələb olunur'),
  body('qiymet_serhedi').optional().isNumeric().withMessage('Qiymət sərhədi ədəd olmalıdır'),
];

const muqavileValidator = [
  body('layihe_id').isInt().withMessage('Layihə ID tələb olunur'),
  body('podratci').trim().notEmpty().withMessage('Podratçı adı tələb olunur'),
  body('mebleg').isNumeric().withMessage('Məbləğ ədəd olmalıdır'),
];

const xercValidator = [
  body('layihe_id').isInt().withMessage('Layihə ID tələb olunur'),
  body('madde_id').isInt().withMessage('Maddə ID tələb olunur'),
  body('mebleg').isNumeric().withMessage('Məbləğ ədəd olmalıdır'),
];

const odenisValidator = [
  body('muqavile_id').isInt().withMessage('Müqavilə ID tələb olunur'),
  body('mebleg').isNumeric().withMessage('Məbləğ ədəd olmalıdır'),
];

const isciValidator = [
  body('ad_soyad').trim().notEmpty().withMessage('Ad soyad tələb olunur'),
  body('vezife_id').isInt().withMessage('Vəzifə ID tələb olunur'),
  body('maas').optional().isNumeric().withMessage('Maaş ədəd olmalıdır'),
];

// ============================================================
// AI VALİDATORLARI
// ============================================================
const teyinatValidator = [
  body('teyinat_novu').trim().notEmpty().withMessage('Teyinat növü tələb olunur'),
  body('agent_id').isInt().withMessage('Agent ID tələb olunur'),
];

const aiTesdiqValidator = [];

/**
 * Validasiya nəticəsini yoxlayan middleware
 */
function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: 'Yoxlama xətası', fields: errors.array() });
  }
  return next();
}

module.exports = {
  registerValidator,
  loginValidator,
  layiheValidator,
  tenderValidator,
  muqavileValidator,
  xercValidator,
  odenisValidator,
  isciValidator,
  teyinatValidator,
  aiTesdiqValidator,
  validate,
};
