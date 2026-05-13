const db = require('../config/db');

/** Sau `auth` — chỉ user có role = admin. (Callback để tương thích Express 4.) */
module.exports = function requireAdmin(req, res, next) {
  if (!req.user || req.user.id == null) {
    return res.status(401).json({ message: 'Cần đăng nhập' });
  }
  db.query('SELECT role FROM users WHERE id = $1', [req.user.id])
    .then((r) => {
      if (r.rows.length === 0 || r.rows[0].role !== 'admin') {
        return res.status(403).json({ message: 'Chỉ quản trị viên mới được thao tác' });
      }
      next();
    })
    .catch((e) => {
      console.error('requireAdmin', e);
      res.status(500).json({ message: 'Lỗi server' });
    });
};
