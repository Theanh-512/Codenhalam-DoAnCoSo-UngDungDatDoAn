/**
 * Một nguồn duy nhất cho JWT (ký + verify).
 * Production: bắt buộc đặt JWT_SECRET trong môi trường.
 */
const DEV_FALLBACK = 'appfood_dev_jwt_unified_v1';

function getJwtSecret() {
  const s = process.env.JWT_SECRET;
  if (s != null && String(s).trim() !== '') {
    return String(s).trim();
  }
  return DEV_FALLBACK;
}

function assertJwtConfigured() {
  if (process.env.NODE_ENV === 'production') {
    const s = process.env.JWT_SECRET;
    if (s == null || String(s).trim() === '') {
      throw new Error('JWT_SECRET is required when NODE_ENV=production');
    }
  }
}

module.exports = { getJwtSecret, assertJwtConfigured };
