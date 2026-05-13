const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { assertJwtConfigured } = require('./config/jwtSecret');
assertJwtConfigured();

const authRoutes = require('./routes/authRoutes');
const foodRoutes = require('./routes/foodRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();

const corsOriginsEnv = process.env.CORS_ORIGINS;
const corsOptions =
  corsOriginsEnv && corsOriginsEnv.trim() !== '' && corsOriginsEnv.trim() !== '*'
    ? {
        origin(origin, callback) {
          if (!origin) return callback(null, true);
          const list = corsOriginsEnv
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean);
          if (list.includes(origin)) return callback(null, true);
          return callback(null, false);
        },
      }
    : {};

// Init Middleware (dev: mở CORS; production: đặt CORS_ORIGINS=url1,url2)
app.use(cors(corsOptions));
app.use(express.json({ extended: false }));

app.get('/api/health', (req, res) => {
  res.json({ ok: true, service: 'appfood-api' });
});

// Define Routes
app.use('/api/auth', authRoutes);
app.use('/api/food', foodRoutes);
app.use('/api/admin', adminRoutes);

app.get('/', (req, res) => {
  res.send('AppFood API is running...');
});

// Mặc định 5050: macOS AirPlay Receiver hay chiếm 5000 và trả 403 cho HTTP.
const PORT = process.env.PORT || 5050;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server started on port ${PORT} (http://localhost:${PORT})`);
});
