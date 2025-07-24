const mysql = require('mysql2/promise');
const { Signer } = require('@aws-sdk/rds-signer');
const { logger } = require('../middleware/errorHandler');

// RDS Signer for generating auth tokens
const signer = new Signer({
  region: process.env.AWS_REGION || 'eu-central-1',
  hostname: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '3306'),
  username: process.env.DB_USER || 'node_example_app'
});

// Function to get auth token
async function getAuthToken() {
  try {
    const token = await signer.getAuthToken();
    return token;
  } catch (error) {
    logger.error('Error getting RDS auth token:', error);
    throw error;
  }
}

// Create connection pool with IAM authentication
let pool;

async function createPool() {
  const authToken = await getAuthToken();
  
  pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'node_example_app',
    password: authToken,
    database: process.env.DB_NAME || 'application',
    ssl: 'Amazon RDS',
    authPlugins: {
      mysql_clear_password: () => () => authToken
    },
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0,
    connectTimeout: 60000,
    acquireTimeout: 60000,
    timeout: 60000
  });

  // Refresh token every 10 minutes (tokens expire after 15 minutes)
  setInterval(async () => {
    try {
      const newToken = await getAuthToken();
      // Update the password for new connections
      pool.config.connectionConfig.password = newToken;
      pool.config.connectionConfig.authPlugins.mysql_clear_password = () => () => newToken;
      logger.info('RDS auth token refreshed');
    } catch (error) {
      logger.error('Error refreshing RDS auth token:', error);
    }
  }, 10 * 60 * 1000);

  return pool;
}

// Test the connection
async function testConnection() {
  try {
    if (!pool) {
      await createPool();
    }
    const connection = await pool.getConnection();
    logger.info('Database connected successfully with IAM authentication');
    connection.release();
  } catch (error) {
    logger.error('Database connection failed:', error);
    throw error;
  }
}

// Initialize database and create users table if it doesn't exist
async function initializeDatabase() {
  try {
    if (!pool) {
      await createPool();
    }
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
    throw error;
  }
}

// Create a wrapper that ensures pool is created before use
const poolWrapper = {
  async execute(...args) {
    if (!pool) {
      await createPool();
    }
    return pool.execute(...args);
  },
  async getConnection() {
    if (!pool) {
      await createPool();
    }
    return pool.getConnection();
  }
};

module.exports = {
  pool: poolWrapper,
  testConnection,
  initializeDatabase
};