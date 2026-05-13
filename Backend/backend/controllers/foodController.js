const db = require('../config/db');
const { pool } = db;

/** Khoảng cách đường chim (km) giữa hai điểm WGS84. */
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/** rule: FREESHIP | GIAM20K | MONKEY10 — khớp logic giỏ hàng app */
function applyVoucherRule(rule, subtotal, deliveryFee) {
  let df = deliveryFee;
  let discount = 0;
  switch (rule) {
    case 'FREESHIP':
      df = 0;
      break;
    case 'GIAM20K': {
      const totalBeforeDiscount = subtotal + df;
      discount = Math.min(20000, totalBeforeDiscount);
      break;
    }
    case 'MONKEY10': {
      const totalBeforeDiscount = subtotal + df;
      const d = subtotal * 0.1;
      discount = Math.min(30000, d, totalBeforeDiscount);
      break;
    }
    default:
      return null;
  }
  return { deliveryFee: df, discount };
}

exports.listVouchers = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT code, rule, title, description
       FROM vouchers WHERE is_active = true ORDER BY code`,
    );
    res.json(result.rows);
  } catch (e) {
    console.error('listVouchers', e);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.getRestaurants = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM restaurants');
    const ulat = parseFloat(req.query.lat);
    const ulng = parseFloat(req.query.lng);
    const hasUser = Number.isFinite(ulat) && Number.isFinite(ulng);

    const rows = result.rows.map((r) => {
      const row = { ...r };
      let dkm = null;
      if (hasUser && r.lat != null && r.lng != null) {
        const rlat = parseFloat(r.lat);
        const rlng = parseFloat(r.lng);
        if (Number.isFinite(rlat) && Number.isFinite(rlng)) {
          dkm = haversineKm(ulat, ulng, rlat, rlng);
        }
      }
      if (dkm != null) {
        row.distance_km = Math.round(dkm * 100) / 100;
      }
      return row;
    });

    if (hasUser) {
      rows.sort((a, b) => {
        const da =
          a.distance_km != null && Number.isFinite(parseFloat(a.distance_km))
            ? parseFloat(a.distance_km)
            : Number.POSITIVE_INFINITY;
        const db =
          b.distance_km != null && Number.isFinite(parseFloat(b.distance_km))
            ? parseFloat(b.distance_km)
            : Number.POSITIVE_INFINITY;
        return da - db;
      });
    }

    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.getCategories = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM categories');
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.getMenuItems = async (req, res) => {
  try {
    const { restaurantId, category } = req.query;
    let queryText = 'SELECT * FROM menu_items WHERE 1=1';
    let params = [];
    let counter = 1;
    if (restaurantId) {
      queryText += ` AND restaurant_id = \$${counter}`;
      params.push(restaurantId);
      counter++;
    }
    if (category) {
      queryText += ` AND category = \$${counter}`;
      params.push(category);
      counter++;
    }
    const result = await db.query(queryText, params);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

exports.searchFood = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) return res.json([]);
    const result = await db.query(
      'SELECT * FROM menu_items WHERE LOWER(name) LIKE $1 OR LOWER(category) LIKE $1',
      [`%${q.toLowerCase()}%`]
    );
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Lỗi server' });
  }
};

// @route POST /api/food/checkout
exports.checkout = async (req, res) => {
  try {
    const {
      total_price: totalPriceRaw,
      delivery_address,
      delivery_lat,
      delivery_lng,
      receiver_name: receiverNameRaw,
      receiver_phone: receiverPhoneRaw,
      payment_method: paymentMethodRaw,
      voucher_code: voucherCodeRaw,
      items,
    } = req.body;

    const receiverName = String(receiverNameRaw || '').trim();
    const receiverPhone = String(receiverPhoneRaw || '').trim();
    const paymentMethod = String(paymentMethodRaw || 'cod')
      .trim()
      .toLowerCase();

    if (!receiverName) {
      return res.status(400).json({ message: 'Vui lòng nhập tên người nhận' });
    }
    if (!receiverPhone || receiverPhone.length < 9) {
      return res
        .status(400)
        .json({ message: 'Vui lòng nhập số điện thoại người nhận hợp lệ' });
    }
    const allowedPay = ['cod', 'ewallet', 'bank'];
    if (!allowedPay.includes(paymentMethod)) {
      return res.status(400).json({ message: 'Phương thức thanh toán không hợp lệ' });
    }

    if (
      !delivery_address ||
      typeof delivery_address !== 'string' ||
      !delivery_address.trim()
    ) {
      return res.status(400).json({ message: 'Thiếu địa chỉ giao hàng' });
    }
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Giỏ hàng trống' });
    }

    const parsed = items
      .map((row) => {
        const restaurantId = String(
          row.restaurantId || row.restaurant_id || '',
        ).trim();
        const menuItemId = String(
          row.menuItemId || row.menu_item_id || '',
        ).trim();
        const quantity = parseInt(String(row.quantity), 10);
        if (!restaurantId || !menuItemId || quantity < 1 || !Number.isFinite(quantity)) {
          return null;
        }
        return { restaurantId, menuItemId, quantity };
      })
      .filter(Boolean);

    if (parsed.length !== items.length) {
      return res.status(400).json({ message: 'Dữ liệu món không hợp lệ' });
    }

    const restaurantIds = [...new Set(parsed.map((i) => i.restaurantId))];
    if (restaurantIds.length !== 1) {
      return res.status(400).json({
        message:
          'Một đơn chỉ từ một nhà hàng. Vui lòng xóa món ở nhà hàng khác trong giỏ.',
      });
    }
    const restaurantId = restaurantIds[0];

    const uniqMenuIds = [...new Set(parsed.map((i) => i.menuItemId))];
    const priceResult = await pool.query(
      `SELECT id, name, price FROM menu_items
       WHERE restaurant_id = $1 AND id = ANY($2::varchar[])`,
      [restaurantId, uniqMenuIds],
    );
    if (priceResult.rows.length !== uniqMenuIds.length) {
      return res.status(400).json({
        message: 'Một hoặc nhiều món không tồn tại hoặc không thuộc nhà hàng này',
      });
    }
    const metaById = new Map(priceResult.rows.map((r) => [r.id, r]));

    const normalized = parsed.map((p) => {
      const m = metaById.get(p.menuItemId);
      const unitPrice = parseFloat(String(m.price));
      if (!Number.isFinite(unitPrice)) return null;
      const name = String(m.name || '').trim() || 'Món';
      return {
        restaurantId: p.restaurantId,
        menuItemId: p.menuItemId,
        name,
        quantity: p.quantity,
        unitPrice,
        lineTotal: p.quantity * unitPrice,
      };
    }).filter(Boolean);

    if (normalized.length !== parsed.length) {
      return res.status(400).json({ message: 'Dữ liệu giá món không hợp lệ' });
    }

    const subtotal = normalized.reduce((s, i) => s + i.lineTotal, 0);
    let deliveryFee = subtotal > 150000 ? 0 : 15000;

    const voucherCode = String(voucherCodeRaw || '')
      .trim()
      .toUpperCase();
    let discount = 0;

    if (voucherCode) {
      const vr = await pool.query(
        `SELECT rule FROM vouchers WHERE UPPER(TRIM(code)) = $1 AND is_active = true`,
        [voucherCode],
      );
      if (vr.rows.length === 0) {
        return res.status(400).json({ message: 'Mã ưu đãi không hợp lệ' });
      }
      const applied = applyVoucherRule(vr.rows[0].rule, subtotal, deliveryFee);
      if (!applied) {
        return res.status(400).json({ message: 'Mã ưu đãi không hợp lệ' });
      }
      deliveryFee = applied.deliveryFee;
      discount = applied.discount;
    }

    const expectedTotal = Math.max(0, subtotal + deliveryFee - discount);
    const clientTotal = parseFloat(totalPriceRaw);
    if (
      !Number.isFinite(clientTotal) ||
      Math.abs(clientTotal - expectedTotal) > 0.5
    ) {
      return res.status(400).json({
        message: 'Tổng tiền không khớp. Vui lòng kiểm tra lại giỏ hàng.',
      });
    }

    const lat =
      delivery_lat != null && delivery_lat !== ''
        ? parseFloat(delivery_lat)
        : null;
    const lng =
      delivery_lng != null && delivery_lng !== ''
        ? parseFloat(delivery_lng)
        : null;

    const userId =
      req.user && req.user.id != null ? parseInt(String(req.user.id), 10) : null;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const orderInsert = await client.query(
        `INSERT INTO orders (
          restaurant_id, subtotal, delivery_fee, total_price,
          delivery_address, delivery_lat, delivery_lng,
          receiver_name, receiver_phone, payment_method,
          user_id, status
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'confirmed') RETURNING id`,
        [
          restaurantId,
          subtotal,
          deliveryFee,
          expectedTotal,
          delivery_address.trim(),
          Number.isFinite(lat) ? lat : null,
          Number.isFinite(lng) ? lng : null,
          receiverName,
          receiverPhone,
          paymentMethod,
          Number.isFinite(userId) ? userId : null,
        ],
      );
      const orderId = orderInsert.rows[0].id;

      for (const row of normalized) {
        await client.query(
          `INSERT INTO order_items (
            order_id, menu_item_id, restaurant_id, name, quantity, unit_price, line_total
          ) VALUES ($1,$2,$3,$4,$5,$6,$7)`,
          [
            orderId,
            row.menuItemId,
            row.restaurantId,
            row.name,
            row.quantity,
            row.unitPrice,
            row.lineTotal,
          ],
        );
      }
      await client.query('COMMIT');
      res.status(201).json({
        orderId,
        total: expectedTotal,
        message: 'Đặt hàng thành công',
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('checkout', error);
    res.status(500).json({ message: 'Không thể tạo đơn hàng' });
  }
};

// @route GET /api/food/my-orders  (Bearer bắt buộc)
exports.getMyOrders = async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await db.query(
      `SELECT
         o.id,
         o.created_at,
         o.total_price,
         o.status,
         o.payment_method,
         o.receiver_name,
         o.receiver_phone,
         o.delivery_address,
         o.subtotal,
         o.delivery_fee,
         r.name AS restaurant_name,
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
       WHERE o.user_id = $1
       ORDER BY o.created_at DESC
       LIMIT 50`,
      [userId],
    );
    res.json(result.rows);
  } catch (err) {
    console.error('getMyOrders', err);
    res.status(500).json({ message: 'Lỗi tải lịch sử đơn' });
  }
};
