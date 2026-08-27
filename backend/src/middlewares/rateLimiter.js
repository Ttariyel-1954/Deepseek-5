const rateLimit = require('express-rate-limit');

const windowMs = parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10);
const limit = parseInt(process.env.RATE_LIMIT_MAX || '200', 10);

/**
 * Ümumi rate limiter — /api üçün
 * Test mühitində (NODE_ENV=test) söndürülür
 */
const limiter = rateLimit({
  windowMs,
  limit,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Çox sayda sorğu göndərildi. Bir az sonra yenidən cəhd edin.' },
});

/**
 * Auth (login/register) üçün daha ciddi limiter
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dəqiqə
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Həddən artıq giriş cəhdi. 15 dəqiqə sonra yenidən cəhd edin.' },
});

module.exports = { limiter, authLimiter };
