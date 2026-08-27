require('dotenv').config();
const app = require('./app');
const logger = require('./middlewares/logger');

const PORT = parseInt(process.env.PORT || '5001', 10);

const server = app.listen(PORT, () => {
  logger.info(`DeepSeek-5 ERP backend ${PORT} portunda işləyir (${process.env.NODE_ENV || 'development'})`);
  logger.info(`AI Mode: ${process.env.AI_MODE || 'mock'}`);
});

// Proses səviyyəli xətalar
process.on('unhandledRejection', (reason) => {
  logger.error('unhandledRejection:', reason);
});

process.on('uncaughtException', (err) => {
  logger.error('uncaughtException:', err);
  process.exit(1);
});

module.exports = server;
