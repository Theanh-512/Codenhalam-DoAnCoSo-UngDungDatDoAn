const db = require('../config/db');
const { pool } = db;

exports.listOrders = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT
         o.id,
         o.created_at,
         o.total_price,
         o.status,
         o.payment_method,
         o.receiver_name,
         o.receiver_phone,
         o.delivery_address,
         o.delivery_lat,
         o.delivery_lng,
         o.subtotal,
         o.delivery_fee,
         o.user_id,
         r.name AS restaurant_name,
         u.email AS user_email,
         COALESCE(
           (SELECT json_agg(
              json_build_object(
                'name', oi.name,
                'quantity', oi.quantity,
                'line_total', oi.line_total
              ) ORDER BY oi.id
            )
            FROM order_items oi WHERE oi.order_id = o.id),
           '[]'::json
         ) AS items
       FROM orders o
       LEFT JOIN restaurants r ON r.id = o.restaurant_id
       LEFT JOIN users u ON u.id = o.user_id
       ORDER BY o.created_at DESC
       LIMIT 200`,
    );
    res.json(result.rows);
  } catch (e) {
    console.error('admin listOrders', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

const ORDER_STATUSES = ['pending', 'confirmed', 'preparing', 'delivering', 'completed', 'cancelled'];

exports.patchOrderStatus = async (req, res) => {
  try {
    const id = parseInt(String(req.params.id), 10);
    const status = String(req.body.status || '').trim().toLowerCase();
    if (!Number.isFinite(id) || id < 1) {
      return res.status(400).json({ message: 'ID đơn không hợp lệ' });
    }
    if (!ORDER_STATUSES.includes(status)) {
      return res.status(400).json({ message: 'Trạng thái không hợp lệ' });
    }
    const r = await pool.query(
      `UPDATE orders SET status = $1 WHERE id = $2 RETURNING id, status`,
      [status, id],
    );
    if (r.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy đơn' });
    }
    res.json(r.rows[0]);
  } catch (e) {
    console.error('admin patchOrderStatus', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.createRestaurant = async (req, res) => {
  try {
    const {
      id,
      name,
      rating,
      review_count,
      type1,
      type2,
      image,
      distance_km,
      lat,
      lng,
    } = req.body;
    const rid = String(id || '').trim();
    if (!rid || !name) {
      return res.status(400).json({ message: 'Thiếu id hoặc tên nhà hàng' });
    }
    const la = lat != null && lat !== '' ? parseFloat(lat) : null;
    const lo = lng != null && lng !== '' ? parseFloat(lng) : null;
    await pool.query(
      `INSERT INTO restaurants (id, name, rating, review_count, type1, type2, image, distance_km, lat, lng)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
      [
        rid,
        String(name).trim(),
        rating != null ? String(rating) : '0',
        review_count != null ? String(review_count) : '0',
        type1 != null ? String(type1) : '',
        type2 != null ? String(type2) : '',
        image != null ? String(image) : '',
        distance_km != null ? parseFloat(distance_km) : 0,
        Number.isFinite(la) ? la : null,
        Number.isFinite(lo) ? lo : null,
      ],
    );
    const row = await pool.query('SELECT * FROM restaurants WHERE id = $1', [rid]);
    res.status(201).json(row.rows[0]);
  } catch (e) {
    if (e.code === '23505') {
      return res.status(400).json({ message: 'ID nhà hàng đã tồn tại' });
    }
    console.error('admin createRestaurant', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.updateRestaurant = async (req, res) => {
  try {
    const id = String(req.params.id || '').trim();
    if (!id) return res.status(400).json({ message: 'Thiếu id' });
    const fields = [];
    const vals = [];
    let i = 1;
    const map = {
      name: 'name',
      rating: 'rating',
      review_count: 'review_count',
      type1: 'type1',
      type2: 'type2',
      image: 'image',
      distance_km: 'distance_km',
    };
    for (const [key, col] of Object.entries(map)) {
      if (req.body[key] !== undefined) {
        fields.push(`${col} = $${i++}`);
        vals.push(req.body[key]);
      }
    }
    if (req.body.lat !== undefined) {
      const la = parseFloat(req.body.lat);
      fields.push(`lat = $${i++}`);
      vals.push(Number.isFinite(la) ? la : null);
    }
    if (req.body.lng !== undefined) {
      const lo = parseFloat(req.body.lng);
      fields.push(`lng = $${i++}`);
      vals.push(Number.isFinite(lo) ? lo : null);
    }
    if (fields.length === 0) {
      return res.status(400).json({ message: 'Không có dữ liệu cập nhật' });
    }
    vals.push(id);
    const r = await pool.query(
      `UPDATE restaurants SET ${fields.join(', ')} WHERE id = $${i} RETURNING *`,
      vals,
    );
    if (r.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy nhà hàng' });
    }
    res.json(r.rows[0]);
  } catch (e) {
    console.error('admin updateRestaurant', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.deleteRestaurant = async (req, res) => {
  try {
    const id = String(req.params.id || '').trim();
    await pool.query('DELETE FROM restaurants WHERE id = $1', [id]);
    res.json({ ok: true });
  } catch (e) {
    console.error('admin deleteRestaurant', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.createCategory = async (req, res) => {
  try {
    const { id, name, image, items_count } = req.body;
    const cid = String(id || '').trim();
    if (!cid || !name) {
      return res.status(400).json({ message: 'Thiếu id hoặc tên danh mục' });
    }
    await pool.query(
      `INSERT INTO categories (id, name, image, items_count) VALUES ($1,$2,$3,$4)`,
      [
        cid,
        String(name).trim(),
        image != null ? String(image) : '',
        items_count != null ? String(items_count) : '0',
      ],
    );
    const row = await pool.query('SELECT * FROM categories WHERE id = $1', [cid]);
    res.status(201).json(row.rows[0]);
  } catch (e) {
    if (e.code === '23505') {
      return res.status(400).json({ message: 'ID danh mục đã tồn tại' });
    }
    console.error('admin createCategory', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.updateCategory = async (req, res) => {
  try {
    const id = String(req.params.id || '').trim();
    const fields = [];
    const vals = [];
    let i = 1;
    for (const col of ['name', 'image', 'items_count']) {
      if (req.body[col] !== undefined) {
        fields.push(`${col} = $${i++}`);
        vals.push(String(req.body[col]));
      }
    }
    if (fields.length === 0) {
      return res.status(400).json({ message: 'Không có dữ liệu cập nhật' });
    }
    vals.push(id);
    const r = await pool.query(
      `UPDATE categories SET ${fields.join(', ')} WHERE id = $${i} RETURNING *`,
      vals,
    );
    if (r.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy danh mục' });
    }
    res.json(r.rows[0]);
  } catch (e) {
    console.error('admin updateCategory', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    const id = String(req.params.id || '').trim();
    await pool.query('DELETE FROM categories WHERE id = $1', [id]);
    res.json({ ok: true });
  } catch (e) {
    console.error('admin deleteCategory', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.createMenuItem = async (req, res) => {
  try {
    const {
      id,
      restaurant_id,
      name,
      description,
      price,
      category,
      emoji,
      image,
      is_best_seller,
    } = req.body;
    const mid = String(id || '').trim();
    const rid = String(restaurant_id || '').trim();
    if (!mid || !rid || !name) {
      return res.status(400).json({ message: 'Thiếu id, restaurant_id hoặc tên món' });
    }
    const p = parseFloat(price);
    if (!Number.isFinite(p) || p < 0) {
      return res.status(400).json({ message: 'Giá không hợp lệ' });
    }
    await pool.query(
      `INSERT INTO menu_items (
        id, restaurant_id, name, description, price, category, emoji, image, is_best_seller
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
      [
        mid,
        rid,
        String(name).trim(),
        description != null ? String(description) : '',
        p,
        category != null ? String(category) : '',
        emoji != null ? String(emoji) : '🍽️',
        image != null ? String(image) : '',
        Boolean(is_best_seller),
      ],
    );
    const row = await pool.query('SELECT * FROM menu_items WHERE id = $1', [mid]);
    res.status(201).json(row.rows[0]);
  } catch (e) {
    if (e.code === '23505') {
      return res.status(400).json({ message: 'ID món đã tồn tại' });
    }
    if (e.code === '23503') {
      return res.status(400).json({ message: 'Nhà hàng không tồn tại' });
    }
    console.error('admin createMenuItem', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.updateMenuItem = async (req, res) => {
  try {
    const id = String(req.params.id || '').trim();
    const fields = [];
    const vals = [];
    let i = 1;
    const map = {
      name: 'name',
      description: 'description',
      price: 'price',
      category: 'category',
      emoji: 'emoji',
      image: 'image',
      is_best_seller: 'is_best_seller',
      restaurant_id: 'restaurant_id',
    };
    for (const [key, col] of Object.entries(map)) {
      if (req.body[key] !== undefined) {
        fields.push(`${col} = $${i++}`);
        if (key === 'price') {
          vals.push(parseFloat(req.body[key]));
        } else if (key === 'is_best_seller') {
          vals.push(Boolean(req.body[key]));
        } else {
          vals.push(req.body[key]);
        }
      }
    }
    if (fields.length === 0) {
      return res.status(400).json({ message: 'Không có dữ liệu cập nhật' });
    }
    vals.push(id);
    const r = await pool.query(
      `UPDATE menu_items SET ${fields.join(', ')} WHERE id = $${i} RETURNING *`,
      vals,
    );
    if (r.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy món' });
    }
    res.json(r.rows[0]);
  } catch (e) {
    console.error('admin updateMenuItem', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.deleteMenuItem = async (req, res) => {
  try {
    const id = String(req.params.id || '').trim();
    await pool.query('DELETE FROM menu_items WHERE id = $1', [id]);
    res.json({ ok: true });
  } catch (e) {
    console.error('admin deleteMenuItem', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

const VOUCHER_RULES = ['FREESHIP', 'GIAM20K', 'MONKEY10'];

exports.listVouchersAdmin = async (req, res) => {
  try {
    const r = await pool.query(
      `SELECT id, code, rule, title, description, is_active, created_at FROM vouchers ORDER BY code`,
    );
    res.json(r.rows);
  } catch (e) {
    console.error('admin listVouchers', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.createVoucher = async (req, res) => {
  try {
    const { code, rule, title, description, is_active } = req.body;
    const c = String(code || '')
      .trim()
      .toUpperCase();
    const r = String(rule || '').trim().toUpperCase();
    if (!c || !VOUCHER_RULES.includes(r)) {
      return res.status(400).json({ message: 'Thiếu mã hoặc rule không hợp lệ (FREESHIP/GIAM20K/MONKEY10)' });
    }
    const active = is_active === undefined ? true : Boolean(is_active);
    await pool.query(
      `INSERT INTO vouchers (code, rule, title, description, is_active)
       VALUES ($1,$2,$3,$4,$5)`,
      [c, r, title != null ? String(title) : '', description != null ? String(description) : '', active],
    );
    const row = await pool.query('SELECT * FROM vouchers WHERE code = $1', [c]);
    res.status(201).json(row.rows[0]);
  } catch (e) {
    if (e.code === '23505') {
      return res.status(400).json({ message: 'Mã voucher đã tồn tại' });
    }
    console.error('admin createVoucher', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.updateVoucher = async (req, res) => {
  try {
    const codeParam = String(req.params.code || '').trim().toUpperCase();
    if (!codeParam) return res.status(400).json({ message: 'Thiếu mã' });
    const { rule, title, description, is_active } = req.body;
    const fields = [];
    const vals = [];
    let i = 1;
    if (rule !== undefined) {
      const r = String(rule).trim().toUpperCase();
      if (!VOUCHER_RULES.includes(r)) {
        return res.status(400).json({ message: 'Rule không hợp lệ' });
      }
      fields.push(`rule = $${i++}`);
      vals.push(r);
    }
    if (title !== undefined) {
      fields.push(`title = $${i++}`);
      vals.push(String(title));
    }
    if (description !== undefined) {
      fields.push(`description = $${i++}`);
      vals.push(String(description));
    }
    if (is_active !== undefined) {
      fields.push(`is_active = $${i++}`);
      vals.push(Boolean(is_active));
    }
    if (fields.length === 0) {
      return res.status(400).json({ message: 'Không có dữ liệu cập nhật' });
    }
    vals.push(codeParam);
    const q = await pool.query(
      `UPDATE vouchers SET ${fields.join(', ')} WHERE UPPER(TRIM(code)) = $${i} RETURNING *`,
      vals,
    );
    if (q.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy voucher' });
    }
    res.json(q.rows[0]);
  } catch (e) {
    console.error('admin updateVoucher', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.deleteVoucher = async (req, res) => {
  try {
    const codeParam = String(req.params.code || '').trim().toUpperCase();
    await pool.query('DELETE FROM vouchers WHERE UPPER(TRIM(code)) = $1', [codeParam]);
    res.json({ ok: true });
  } catch (e) {
    console.error('admin deleteVoucher', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.listUsers = async (req, res) => {
  try {
    const r = await pool.query(
      `SELECT id, fullname, email, phone, address, role, is_active, created_at
       FROM users ORDER BY id DESC LIMIT 500`,
    );
    res.json(r.rows);
  } catch (e) {
    console.error('admin listUsers', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.patchUser = async (req, res) => {
  try {
    const id = parseInt(String(req.params.id), 10);
    if (!Number.isFinite(id) || id < 1) {
      return res.status(400).json({ message: 'ID không hợp lệ' });
    }
    if (id === req.user.id) {
      if (req.body.is_active === false) {
        return res.status(400).json({ message: 'Không thể khóa chính mình' });
      }
      if (req.body.role && req.body.role !== 'admin') {
        return res.status(400).json({ message: 'Không thể tự bỏ quyền admin tại đây' });
      }
    }
    const { fullname, phone, address, role, is_active } = req.body;
    const fields = [];
    const vals = [];
    let i = 1;
    if (fullname !== undefined) {
      fields.push(`fullname = $${i++}`);
      vals.push(String(fullname).trim());
    }
    if (phone !== undefined) {
      fields.push(`phone = $${i++}`);
      vals.push(String(phone).trim());
    }
    if (address !== undefined) {
      fields.push(`address = $${i++}`);
      vals.push(String(address).trim());
    }
    if (role !== undefined) {
      const r = String(role).trim().toLowerCase();
      if (r !== 'user' && r !== 'admin') {
        return res.status(400).json({ message: 'role không hợp lệ' });
      }
      fields.push(`role = $${i++}`);
      vals.push(r);
    }
    if (is_active !== undefined) {
      fields.push(`is_active = $${i++}`);
      vals.push(Boolean(is_active));
    }
    if (fields.length === 0) {
      return res.status(400).json({ message: 'Không có dữ liệu cập nhật' });
    }
    vals.push(id);
    const r = await pool.query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${i}
       RETURNING id, fullname, email, phone, address, role, is_active, created_at`,
      vals,
    );
    if (r.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }
    res.json(r.rows[0]);
  } catch (e) {
    console.error('admin patchUser', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};
