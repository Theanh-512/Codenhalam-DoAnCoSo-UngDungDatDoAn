const bcrypt = require('bcrypt');

/** Tài khoản thử nghiệm nếu DB chưa có user (đăng nhập app). */
const seedDemoUser = async (pool) => {
  try {
    const demoEmail = 'demo@appfood.com';
    const u = await pool.query('SELECT id FROM users WHERE LOWER(TRIM(email)) = $1', [
      demoEmail,
    ]);
    if (u.rows.length > 0) return;
    const hash = await bcrypt.hash('demo123456', 10);
    await pool.query(
      'INSERT INTO users (fullname, email, password, phone, address) VALUES ($1, $2, $3, $4, $5)',
      ['Tài khoản demo', demoEmail, hash, '', ''],
    );
    console.log('Demo login: demo@appfood.com / demo123456');
  } catch (e) {
    console.error('seedDemoUser:', e.message);
  }
};

const seedData = async (pool) => {
  try {
    const resCount = await pool.query('SELECT COUNT(*) FROM restaurants');
    if (parseInt(resCount.rows[0].count) > 0) {
      console.log('Database already has food data. Skipping seed.');
      return;
    }

    console.log('No food data found. Seeding database with mock data...');

    // 1. Seed Restaurants
    // distance_km cột legacy; khoảng cách hiển thị tính từ lat/lng nhà hàng + vị trí khách (API).
    const restaurants = [
      ["r1", "Cơm tấm ngon", "4.8", "305", "Cơm tấm", "Vietnamese", "https://loremflickr.com/400/400/restaurant?random=1", 0, 10.7819, 106.6974],
      ["r2", "Phở bò Hà Nội", "4.9", "124", "Phở", "Traditional", "https://loremflickr.com/400/400/restaurant?random=2", 0, 10.7736, 106.7042],
      ["r3", "Burger King", "4.5", "500", "Burger", "Fast Food", "https://loremflickr.com/400/400/restaurant?random=3", 0, 10.7865, 106.712],
      ["r4", "Pizza Hut", "4.7", "410", "Pizza", "Italian", "https://loremflickr.com/400/400/restaurant?random=4", 0, 10.7688, 106.6895],
      ["r5", "Bánh mì Hội An", "4.9", "890", "Bánh mì", "Street Food", "https://loremflickr.com/400/400/restaurant?random=5", 0, 10.7752, 106.7018],
    ];
    for (let r of restaurants) {
      await pool.query(
        "INSERT INTO restaurants (id, name, rating, review_count, type1, type2, image, distance_km, lat, lng) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
        r
      );
    }

    // 2. Seed Categories
    const categories = [
      ["c1", "Món chính", "https://loremflickr.com/400/400/food?random=c1", "120"],
      ["c2", "Đồ uống", "https://loremflickr.com/400/400/food?random=c2", "220"],
      ["c3", "Tráng miệng", "https://loremflickr.com/400/400/food?random=c3", "155"],
      ["c4", "Khuyến mãi", "https://loremflickr.com/400/400/food?random=c4", "25"]
    ];
    for (let c of categories) {
      await pool.query(
        "INSERT INTO categories (id, name, image, items_count) VALUES ($1, $2, $3, $4)",
        c
      );
    }

    // 3. Seed Menu Items
    const menuItems = [
      ["m1", "r1", "Cơm tấm sườn bì chả", "Cơm tấm với sườn nướng, bì heo, chả trứng", 55000, "Món chính", "🍚", true],
      ["m2", "r1", "Cơm tấm sườn nướng", "Sườn nướng mật ong thơm ngon", 50000, "Món chính", "🍚", false],
      ["m3", "r1", "Cơm tấm bì chả", "Bì heo và chả trứng hấp", 45000, "Món chính", "🍚", false],
      ["m4", "r1", "Nước ngọt", "Coca, Pepsi, 7Up", 15000, "Đồ uống", "🥤", false],
      ["m5", "r1", "Trà đá", "Trà đá miễn phí", 0, "Đồ uống", "🍵", false],

      ["m6", "r2", "Phở bò tái", "Phở bò với thịt tái thơm, nước dùng đậm đà", 60000, "Món chính", "🍜", true],
      ["m7", "r2", "Phở bò chín", "Thịt bò chín mềm, nước trong", 60000, "Món chính", "🍜", false],
      ["m8", "r2", "Phở gà", "Phở gà ta luộc vàng", 55000, "Món chính", "🍜", false],
      ["m9", "r2", "Quẩy giòn", "2 cái quẩy chiên giòn", 10000, "Khai vị", "🥐", false],
      ["m10", "r2", "Nước chanh", "Chanh tươi đá lạnh", 20000, "Đồ uống", "🍋", false],

      ["m11", "r3", "Whopper", "Bánh burger bò 100g với rau xà lách, cà chua", 89000, "Món chính", "🍔", true],
      ["m12", "r3", "Double Whopper", "2 lớp thịt bò siêu ngon", 119000, "Món chính", "🍔", false],
      ["m13", "r3", "Chicken Burger", "Gà giòn sốt mayonnaise", 79000, "Món chính", "🍔", false],
      ["m14", "r3", "Khoai tây chiên", "Vừa/Lớn, giòn tan", 35000, "Khai vị", "🍟", false],
      ["m15", "r3", "Coca Cola", "330ml", 25000, "Đồ uống", "🥤", false],

      ["m16", "r4", "Pizza Margherita", "Cà chua, phô mai mozzarella, húng quế", 150000, "Món chính", "🍕", true],
      ["m17", "r4", "Pizza BBQ Chicken", "Gà nướng BBQ, hành tây, ớt chuông", 175000, "Món chính", "🍕", false],
      ["m18", "r4", "Garlic Bread", "Bánh mì bơ tỏi nướng", 45000, "Khai vị", "🥖", false],

      ["m19", "r5", "Bánh mì đặc biệt", "Pate, thịt nguội, chả, rau thơm", 35000, "Món chính", "🥖", true],
      ["m20", "r5", "Bánh mì trứng", "2 trứng chiên, dưa leo, cà rốt", 25000, "Món chính", "🥖", false],
      ["m21", "r5", "Bánh mì gà", "Gà xé, sốt tương ớt", 30000, "Món chính", "🥖", false],
      ["m22", "r5", "Cà phê sữa đá", "Cà phê phin truyền thống", 20000, "Đồ uống", "☕", false],

      ["m23", "r1", "Bánh Flan", "Bánh flan caramen béo ngậy", 20000, "Tráng miệng", "🍮", false],
      ["m24", "r2", "Chè hạt sen", "Chè hạt sen long nhãn mát lạnh", 25000, "Tráng miệng", "🍧", false],
      ["m25", "r3", "Kem tươi Sundae", "Kem vani xốt sôcôla", 30000, "Tráng miệng", "🍦", false],

      ["m26", "r4", "Combo Pizza Mua 1 Tặng 1", "Áp dụng cho pizza cỡ lớn", 250000, "Khuyến mãi", "🎉", true],
      ["m27", "r5", "Bánh mì + Cafe sáng", "Khuyến mãi chào buổi sáng", 40000, "Khuyến mãi", "🎁", true]
    ];
    for (let item of menuItems) {
      await pool.query(
        "INSERT INTO menu_items (id, restaurant_id, name, description, price, category, emoji, is_best_seller) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
        item
      );
    }

    console.log('Food Database successfully seeded!');
  } catch (error) {
    console.error('Error seeding database:', error);
  }
};

/** Tài khoản quản trị (đăng nhập app → tab Khác → Quản trị). */
const seedAdminUser = async (pool) => {
  try {
    const email = 'admin@appfood.com';
    const hash = await bcrypt.hash('admin123456', 10);
    const u = await pool.query('SELECT id FROM users WHERE LOWER(TRIM(email)) = $1', [
      email,
    ]);
    if (u.rows.length > 0) {
      await pool.query('UPDATE users SET role = $1 WHERE id = $2', ['admin', u.rows[0].id]);
      return;
    }
    await pool.query(
      'INSERT INTO users (fullname, email, password, role) VALUES ($1, $2, $3, $4)',
      ['Quản trị viên', email, hash, 'admin'],
    );
    console.log('Admin login: admin@appfood.com / admin123456');
  } catch (e) {
    console.error('seedAdminUser:', e.message);
  }
};

/** Voucher mặc định (checkout đọc từ bảng vouchers). */
const seedVouchers = async (pool) => {
  try {
    const n = await pool.query('SELECT COUNT(*)::int AS c FROM vouchers');
    if (n.rows[0].c > 0) return;
    const rows = [
      ['FREESHIP', 'FREESHIP', 'Miễn phí ship', 'Miễn phí giao hàng', true],
      ['GIAM20K', 'GIAM20K', 'Giảm 20.000đ', 'Giảm tối đa 20.000đ', true],
      ['MONKEY10', 'MONKEY10', 'Giảm 10%', 'Giảm 10% tối đa 30.000đ', true],
    ];
    for (const r of rows) {
      await pool.query(
        `INSERT INTO vouchers (code, rule, title, description, is_active) VALUES ($1,$2,$3,$4,$5)`,
        r,
      );
    }
    console.log('Seeded default vouchers (FREESHIP, GIAM20K, MONKEY10).');
  } catch (e) {
    console.error('seedVouchers:', e.message);
  }
};

/** DB cũ đã có nhà hàng nhưng thiếu tọa độ — gán tọa độ mẫu quanh TP.HCM. */
const seedRestaurantCoords = async (pool) => {
  try {
    const list = [
      ['r1', 10.7819, 106.6974],
      ['r2', 10.7736, 106.7042],
      ['r3', 10.7865, 106.712],
      ['r4', 10.7688, 106.6895],
      ['r5', 10.7752, 106.7018],
    ];
    for (const [id, la, lo] of list) {
      await pool.query(
        `UPDATE restaurants SET lat = $1, lng = $2 WHERE id = $3 AND (lat IS NULL OR lng IS NULL)`,
        [la, lo, id],
      );
    }
  } catch (e) {
    console.error('seedRestaurantCoords:', e.message);
  }
};

module.exports = { seedData, seedDemoUser, seedAdminUser, seedVouchers, seedRestaurantCoords };
