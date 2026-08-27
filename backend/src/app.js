require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

const db = require('./config/db');
const logger = require('./middlewares/logger');
const { limiter } = require('./middlewares/rateLimiter');
const { notFound, errorHandler } = require('./middlewares/errorHandler');
const { authenticate } = require('./middlewares/auth');
const aiController = require('./controllers/aiController');

const authRoutes = require('./routes/authRoutes');
const layiheRoutes = require('./routes/layiheRoutes');
const tenderRoutes = require('./routes/tenderRoutes');
const muqavileRoutes = require('./routes/muqavileRoutes');
const xercRoutes = require('./routes/xercRoutes');
const odenisRoutes = require('./routes/odenisRoutes');
const isciRoutes = require('./routes/isciRoutes');
const aiRoutes = require('./routes/aiRoutes');

const app = express();

// ============================================================
// QLOBAL MIDDLEWARES
// ============================================================
app.use(helmet());
app.use(
  cors({
    origin: (process.env.CORS_ORIGIN || '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean),
  })
);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined'));
  app.use('/api', limiter);
}

// ============================================================
// HEALTH
// ============================================================
app.get('/api/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    return res.json({
      status: 'ok',
      db: 'ok',
      uptime: process.uptime(),
      time: new Date().toISOString(),
    });
  } catch (err) {
    logger.error('Health yoxlaması xətası:', err.message);
    return res.status(500).json({ status: 'error', db: 'error', message: err.message });
  }
});

// ============================================================
// AI STATUS (app.js-də ayrıca — sistemin ümumi AI vəziyyəti)
// ============================================================
app.get('/api/ai/status', authenticate, aiController.getStatus);

// ============================================================
// ROUTLAR
// ============================================================
app.use('/api/auth', authRoutes);
app.use('/api/layihe', layiheRoutes);
app.use('/api/tender', tenderRoutes);
app.use('/api/muqavile', muqavileRoutes);
app.use('/api/xerc', xercRoutes);
app.use('/api/odenis', odenisRoutes);
app.use('/api/isci', isciRoutes);
app.use('/api/ai', aiRoutes);

// ============================================================
// 404 + XƏTA EMALI
// ============================================================
app.use(notFound);
app.use(errorHandler);

module.exports = app;
