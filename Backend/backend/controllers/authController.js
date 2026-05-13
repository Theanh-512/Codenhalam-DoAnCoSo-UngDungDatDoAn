const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { getJwtSecret } = require('../config/jwtSecret');

const JWT_EXPIRES = '30d';

// @route   POST /api/auth/register
// @desc    Register a user
const register = async (req, res) => {
  const { fullname, password, phone, address } = req.body;
  const email = (req.body.email || '').trim().toLowerCase();

  try {
    if (!email || !password) {
      return res.status(400).json({ message: 'Email và mật khẩu là bắt buộc' });
    }
    // 1. Check if user exists
    const userCheck = await db.query('SELECT * FROM users WHERE LOWER(TRIM(email)) = $1', [email]);
    if (userCheck.rows.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // 2. Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 3. Insert user into db
    const newUser = await db.query(
      'INSERT INTO users (fullname, email, password, phone, address) VALUES ($1, $2, $3, $4, $5) RETURNING id, fullname, email, phone, address, role, is_active',
      [fullname, email, hashedPassword, phone, address]
    );

    // 4. Create and return JWT
    const payload = {
      user: {
        id: newUser.rows[0].id,
      },
    };

    jwt.sign(
      payload,
      getJwtSecret(),
      { expiresIn: JWT_EXPIRES },
      (err, token) => {
        if (err) throw err;
        res.status(201).json({ token, user: newUser.rows[0] });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};

// @route   POST /api/auth/login
// @desc    Authenticate user & get token
const login = async (req, res) => {
  const email = (req.body.email || '').trim().toLowerCase();
  const { password } = req.body;

  try {
    if (!email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu' });
    }
    // 1. Check if user exists (không phân biệt hoa thường)
    const userResult = await db.query(
      'SELECT id, fullname, email, password, phone, address, role, is_active, created_at FROM users WHERE LOWER(TRIM(email)) = $1',
      [email],
    );
    if (userResult.rows.length === 0) {
      return res.status(400).json({ message: 'Invalid Credentials' });
    }

    const user = userResult.rows[0];

    if (user.is_active === false) {
      return res.status(403).json({ message: 'Tài khoản đã bị khóa' });
    }

    // 2. Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid Credentials' });
    }

    // 3. Return JWT
    const payload = {
      user: {
        id: user.id,
      },
    };

    jwt.sign(
      payload,
      getJwtSecret(),
      { expiresIn: JWT_EXPIRES },
      (err, token) => {
        if (err) throw err;
        const userWithoutPassword = { ...user };
        delete userWithoutPassword.password;
        res.json({ token, user: userWithoutPassword });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};

// @route   GET /api/auth/profile
// @desc    Get user profile
const getProfile = async (req, res) => {
  try {
    const userResult = await db.query(
      'SELECT id, fullname, email, phone, address, role, is_active, created_at FROM users WHERE id = $1',
      [req.user.id]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(userResult.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};

// @route   POST /api/auth/social
// @desc    Social Login (Google/Facebook)
const socialLogin = async (req, res) => {
  const { fullname, provider, provider_id } = req.body;
  const email = (req.body.email || '').trim().toLowerCase();

  try {
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }
    // 1. Check if user already exists
    let userResult = await db.query('SELECT * FROM users WHERE LOWER(TRIM(email)) = $1', [email]);
    let user;

    if (userResult.rows.length > 0) {
      user = userResult.rows[0];
      if (user.is_active === false) {
        return res.status(403).json({ message: 'Tài khoản đã bị khóa' });
      }
    } else {
      // 2. If not exists, register a new user automatically
      const generatedPassword = await bcrypt.hash(provider_id || Math.random().toString(36), 10);
      const newUser = await db.query(
        'INSERT INTO users (fullname, email, password) VALUES ($1, $2, $3) RETURNING id, fullname, email, role, is_active',
        [fullname || 'Social User', email, generatedPassword]
      );
      user = newUser.rows[0];
    }

    // 3. Create and return JWT
    const payload = {
      user: { id: user.id },
    };

    jwt.sign(
      payload,
      getJwtSecret(),
      { expiresIn: JWT_EXPIRES },
      (err, token) => {
        if (err) throw err;
        const userWithoutPassword = { ...user };
        delete userWithoutPassword.password;
        res.json({ token, user: userWithoutPassword });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};

// POST /api/auth/forgot-password — tạo mã OTP 6 số (15 phút). Gửi email: mở rộng sau.
// Đặt RESET_OTP_IN_RESPONSE=1 trong .env để API trả thêm debug_otp (demo / dev).
const forgotPassword = async (req, res) => {
  const email = (req.body.email || '').trim().toLowerCase();
  if (!email) {
    return res.status(400).json({ message: 'Vui lòng nhập email' });
  }
  try {
    const userResult = await db.query(
      'SELECT id FROM users WHERE LOWER(TRIM(email)) = $1',
      [email],
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy tài khoản với email này' });
    }
    const code = String(Math.floor(100000 + Math.random() * 900000));
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
    await db.query('DELETE FROM password_resets WHERE email = $1', [email]);
    await db.query(
      'INSERT INTO password_resets (email, code, expires_at) VALUES ($1, $2, $3)',
      [email, code, expiresAt],
    );
    console.log(`[password-reset] ${email} OTP=${code} (hết hạn sau 15 phút)`);
    const body = {
      message: 'Đã tạo mã xác nhận. Kiểm tra email (hoặc console server khi chưa cấu hình SMTP).',
      expiresInMinutes: 15,
    };
    if (
      process.env.RESET_OTP_IN_RESPONSE === '1' ||
      process.env.RESET_OTP_IN_RESPONSE === 'true'
    ) {
      body.debug_otp = code;
    }
    return res.json(body);
  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ message: 'Server Error' });
  }
};

// POST /api/auth/reset-password — { email, code, newPassword }
const resetPassword = async (req, res) => {
  const email = (req.body.email || '').trim().toLowerCase();
  const code = req.body.code != null ? String(req.body.code).trim() : '';
  const { newPassword } = req.body;
  if (!email || !code || !newPassword) {
    return res.status(400).json({ message: 'Thiếu email, mã OTP hoặc mật khẩu mới' });
  }
  if (String(newPassword).length < 6) {
    return res.status(400).json({ message: 'Mật khẩu mới tối thiểu 6 ký tự' });
  }
  try {
    const row = await db.query(
      `SELECT id FROM password_resets WHERE email = $1 AND code = $2 AND expires_at > NOW()`,
      [email, code],
    );
    if (row.rows.length === 0) {
      return res.status(400).json({ message: 'Mã không đúng hoặc đã hết hạn' });
    }
    const salt = await bcrypt.genSalt(10);
    const hashed = await bcrypt.hash(String(newPassword), salt);
    await db.query('UPDATE users SET password = $1 WHERE LOWER(TRIM(email)) = $2', [
      hashed,
      email,
    ]);
    await db.query('DELETE FROM password_resets WHERE email = $1', [email]);
    return res.json({ message: 'Đặt lại mật khẩu thành công' });
  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ message: 'Server Error' });
  }
};

// PATCH /api/auth/profile
const updateProfile = async (req, res) => {
  const { fullname, phone, address } = req.body;
  const updates = [];
  const vals = [];
  let i = 1;
  if (fullname !== undefined && fullname !== null) {
    updates.push(`fullname = $${i++}`);
    vals.push(String(fullname).trim());
  }
  if (phone !== undefined && phone !== null) {
    updates.push(`phone = $${i++}`);
    vals.push(String(phone).trim());
  }
  if (address !== undefined && address !== null) {
    updates.push(`address = $${i++}`);
    vals.push(String(address).trim());
  }
  if (updates.length === 0) {
    return res.status(400).json({ message: 'Không có dữ liệu cập nhật' });
  }
  try {
    vals.push(req.user.id);
    const sql = `UPDATE users SET ${updates.join(', ')} WHERE id = $${i} RETURNING id, fullname, email, phone, address, created_at`;
    const result = await db.query(sql, vals);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    return res.json(result.rows[0]);
  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ message: 'Server Error' });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  socialLogin,
  forgotPassword,
  resetPassword,
  updateProfile,
};
