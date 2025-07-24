var express = require('express');
var router = express.Router();
const { pool } = require('../config/database');
const kubernetesService = require('../services/kubernetesService');
const { logger } = require('../middleware/errorHandler');

/* Health check endpoint */
router.get('/health', async function(req, res) {
  const checks = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks: {}
  };

  // Database health check
  try {
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    checks.checks.database = { status: 'healthy' };
  } catch (error) {
    checks.status = 'degraded';
    checks.checks.database = { 
      status: 'unhealthy', 
      error: error.message 
    };
    logger.error('Database health check failed', { error: error.message });
  }

  // Kubernetes client health check
  checks.checks.kubernetes = {
    status: kubernetesService.isHealthy() ? 'healthy' : 'unhealthy'
  };

  // Memory usage check
  const memUsage = process.memoryUsage();
  checks.checks.memory = {
    status: 'healthy',
    heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
    heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB',
    rss: Math.round(memUsage.rss / 1024 / 1024) + 'MB'
  };

  const statusCode = checks.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(checks);
});

/* Liveness probe endpoint */
router.get('/health/live', function(req, res) {
  res.status(200).json({ status: 'alive' });
});

/* Readiness probe endpoint */
router.get('/health/ready', async function(req, res) {
  let isReady = true;
  
  // Check database connection
  try {
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
  } catch (error) {
    isReady = false;
    logger.error('Readiness check failed - database', { error: error.message });
  }

  if (isReady) {
    res.status(200).json({ status: 'ready' });
  } else {
    res.status(503).json({ status: 'not ready' });
  }
});

module.exports = router;