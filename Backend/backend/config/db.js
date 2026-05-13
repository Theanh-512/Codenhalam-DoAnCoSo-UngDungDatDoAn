require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'appfood_db',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

pool.on('connect', () => {
  console.log('Connected to PostgreSQL Database');
});

// Create tables if they don't exist
const createTables = async () => {
  const queryText = `
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      fullname VARCHAR(100) NOT NULL,
      email VARCHAR(100) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL,
      phone VARCHAR(20),
      address VARCHAR(255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;
  try {
    await pool.query(queryText);
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS address VARCHAR(255);');
    await pool.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';`,
    );
    await pool.query(`UPDATE users SET role = 'user' WHERE role IS NULL OR role = '';`);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS password_resets (
        id SERIAL PRIMARY KEY,
        email VARCHAR(100) NOT NULL,
        code VARCHAR(6) NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    await pool.query(
      `CREATE INDEX IF NOT EXISTS idx_password_resets_email ON password_resets(email);`,
    );
    
    // Create Food tables
    const foodTablesText = `
      CREATE TABLE IF NOT EXISTS restaurants (
        id VARCHAR(50) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        rating VARCHAR(10),
        review_count VARCHAR(50),
        type1 VARCHAR(100),
        type2 VARCHAR(100),
        image TEXT,
        distance_km DOUBLE PRECISION
      );

      CREATE TABLE IF NOT EXISTS categories (
        id VARCHAR(50) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        image TEXT,
        items_count VARCHAR(50)
      );

      CREATE TABLE IF NOT EXISTS menu_items (
        id VARCHAR(50) PRIMARY KEY,
        restaurant_id VARCHAR(50) REFERENCES restaurants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DOUBLE PRECISION,
        category VARCHAR(100),
        emoji VARCHAR(10),
        is_best_seller BOOLEAN DEFAULT FALSE
      );

      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        restaurant_id VARCHAR(50) REFERENCES restaurants(id),
        subtotal DOUBLE PRECISION NOT NULL DEFAULT 0,
        delivery_fee DOUBLE PRECISION NOT NULL DEFAULT 0,
        total_price DOUBLE PRECISION NOT NULL,
        delivery_address TEXT,
        delivery_lat DOUBLE PRECISION,
        delivery_lng DOUBLE PRECISION,
        receiver_name VARCHAR(120),
        receiver_phone VARCHAR(30),
        payment_method VARCHAR(40),
        user_id INTEGER REFERENCES users(id),
        status VARCHAR(50) DEFAULT 'pending'
      );

      CREATE TABLE IF NOT EXISTS order_items (
        id SERIAL PRIMARY KEY,
        order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        menu_item_id VARCHAR(50),
        restaurant_id VARCHAR(50),
        name VARCHAR(255) NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price DOUBLE PRECISION NOT NULL,
        line_total DOUBLE PRECISION NOT NULL
      );
    `;
    await pool.query(foodTablesText);

    // Migration nhẹ: nếu bảng đã tồn tại từ phiên bản cũ, `CREATE TABLE IF NOT EXISTS`
    // sẽ không thêm cột mới. Checkout sẽ fail nếu thiếu cột.
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS restaurant_id VARCHAR(50);`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS subtotal DOUBLE PRECISION NOT NULL DEFAULT 0;`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS delivery_fee DOUBLE PRECISION NOT NULL DEFAULT 0;`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS total_price DOUBLE PRECISION NOT NULL DEFAULT 0;`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS delivery_address TEXT;`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS delivery_lat DOUBLE PRECISION;`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS delivery_lng DOUBLE PRECISION;`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'pending';`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS receiver_name VARCHAR(120);`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS receiver_phone VARCHAR(30);`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS payment_method VARCHAR(40);`,
    );
    await pool.query(
      `ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id);`,
    );

    await pool.query(
      `ALTER TABLE order_items
        ADD COLUMN IF NOT EXISTS restaurant_id VARCHAR(50);`,
    );
    await pool.query(
      `ALTER TABLE order_items
        ADD COLUMN IF NOT EXISTS menu_item_id VARCHAR(50);`,
    );
    await pool.query(
      `ALTER TABLE order_items
        ADD COLUMN IF NOT EXISTS name VARCHAR(255) NOT NULL DEFAULT '';`,
    );
    await pool.query(
      `ALTER TABLE order_items
        ADD COLUMN IF NOT EXISTS quantity INTEGER NOT NULL DEFAULT 1;`,
    );
    await pool.query(
      `ALTER TABLE order_items
        ADD COLUMN IF NOT EXISTS unit_price DOUBLE PRECISION NOT NULL DEFAULT 0;`,
    );
    await pool.query(
      `ALTER TABLE order_items
        ADD COLUMN IF NOT EXISTS line_total DOUBLE PRECISION NOT NULL DEFAULT 0;`,
    );
    await pool.query(`ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS image TEXT;`);
    await pool.query(
      `ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION;`,
    );
    await pool.query(
      `ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION;`,
    );
    await pool.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;`,
    );
    await pool.query(`UPDATE users SET is_active = TRUE WHERE is_active IS NULL;`);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS vouchers (
        id SERIAL PRIMARY KEY,
        code VARCHAR(40) UNIQUE NOT NULL,
        rule VARCHAR(32) NOT NULL,
        title VARCHAR(255),
        description TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('All Database tables initialized successfully');

    // Run seed data
    const seed = require('./seed');
    try {
      await seed.seedData(pool);
    } catch (err) {
      console.log('Seed file not fully ready or error:', err.message);
    }
    try {
      await seed.seedDemoUser(pool);
    } catch (err) {
      console.log('seedDemoUser error:', err.message);
    }
    try {
      await seed.seedAdminUser(pool);
    } catch (err) {
      console.log('seedAdminUser error:', err.message);
    }
    try {
      await seed.seedVouchers(pool);
    } catch (err) {
      console.log('seedVouchers error:', err.message);
    }
    try {
      await seed.seedRestaurantCoords(pool);
    } catch (err) {
      console.log('seedRestaurantCoords error:', err.message);
    }
  } catch (error) {
    console.error('Error creating users table:', error);
  }
};

createTables();

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
