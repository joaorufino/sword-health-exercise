var express = require('express');
var router = express.Router();
var { pool } = require('../config/database');
const { logger } = require('../middleware/errorHandler');
const { retry } = require('../utils/retry');

/* GET users page */
router.get('/', function(req, res, next) {
  res.render('users', { title: 'Users from MySQL Database' });
});

/* API endpoint to get all users from database */
router.get('/api/list', async function(req, res, next) {
  try {
    const [rows] = await retry(async () => {
      return await pool.execute('SELECT id, name, email, created_at FROM users ORDER BY id');
    }, {
      retries: 3,
      delay: 500,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying database query (attempt ${attempt})`, { error: error.message });
      }
    });
    
    res.json({
      success: true,
      users: rows,
      count: rows.length
    });
  } catch (error) {
    logger.error('Failed to fetch users', { error: error.message });
    next(error);
  }
});

/* API endpoint to add a new user */
router.post('/api/add', async function(req, res, next) {
  const { name, email } = req.body;
  
  if (!name || !email) {
    const error = new Error('Name and email are required');
    error.status = 400;
    return next(error);
  }
  
  try {
    const [result] = await retry(async () => {
      return await pool.execute(
        'INSERT INTO users (name, email) VALUES (?, ?)',
        [name, email]
      );
    });
    
    res.json({
      success: true,
      message: 'User added successfully',
      userId: result.insertId
    });
  } catch (error) {
    logger.error('Failed to add user', { name, email, error: error.message });
    if (error.code === 'ER_DUP_ENTRY') {
      const dupError = new Error('Email already exists');
      dupError.status = 400;
      next(dupError);
    } else {
      next(error);
    }
  }
});

/* API endpoint to delete a user */
router.delete('/api/delete/:id', async function(req, res, next) {
  const userId = req.params.id;
  
  try {
    const [result] = await retry(async () => {
      return await pool.execute(
        'DELETE FROM users WHERE id = ?',
        [userId]
      );
    });
    
    if (result.affectedRows === 0) {
      const error = new Error('User not found');
      error.status = 404;
      return next(error);
    }
    
    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    logger.error('Failed to delete user', { userId, error: error.message });
    next(error);
  }
});

module.exports = router;
