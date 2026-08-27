const logger = require('./logger');

/**
 * 404 — tapılmayan endpoint
 */
function notFound(req, res) {
  res.status(404).json({ error: 'Tapılmadı', path: req.originalUrl });
}

/**
 * Mərkəzi xəta emalı middleware-i
 */
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  const status = err.statusCode || 500;
  const message = err.message || 'Daxili server xətası';

  if (status >= 500) {
    logger.error(`${req.method} ${req.originalUrl} — ${message}`, { stack: err.stack });
  }

  if (res.headersSent) {
    return next(err);
  }

  return res.status(status).json({
    error: status >= 500 ? 'Daxili server xətası' : message,
    ...(status >= 500 ? { message } : {}),
  });
}

module.exports = { notFound, errorHandler };
