const mysql = require('mysql2/promise');
const { logger } = require('../middleware/errorHandler');

// Use IAM authentication if enabled
if (process.env.USE_IAM_AUTH === 'true') {
  module.exports = require('./database-iam');
  return;
}

// Create connection pool for better performance and connection management
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'mysql',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'myapp',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  connectTimeout: 60000,
  acquireTimeout: 60000,
  timeout: 60000
});

// Test the connection
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    logger.info('Database connected successfully');
    connection.release();
  } catch (error) {
    logger.error('Database connection failed:', error);
  }
}

// Initialize database and create users table if it doesn't exist
async function initializeDatabase() {
  try {
    const connection = await pool.getConnection();
    
    // Create users table if it doesn't exist
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Check if table is empty and insert sample data
    const [rows] = await connection.execute('SELECT COUNT(*) as count FROM users');
    if (rows[0].count === 0) {
      await connection.execute(`
        INSERT INTO users (name, email) VALUES 
        ('John Doe', 'john@example.com'),
        ('Jane Smith', 'jane@example.com'),
        ('Bob Johnson', 'bob@example.com')
      `);
      logger.info('Sample users data inserted');
    }
    
    connection.release();
    logger.info('Database initialized successfully');
  } catch (error) {
    logger.error('Database initialization error:', error);
  }
}

// Create a wrapper that works for both sync and async pools
const poolWrapper = {
  async execute(...args) {
    return pool.execute(...args);
  },
  async getConnection() {
    return pool.getConnection();
  }
};

module.exports = {
  pool: poolWrapper,
  testConnection,
  initializeDatabase
};