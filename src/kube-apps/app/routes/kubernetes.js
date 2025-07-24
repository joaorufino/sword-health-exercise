var express = require('express');
var router = express.Router();
const kubernetesService = require('../services/kubernetesService');
const { logger } = require('../middleware/errorHandler');

/* GET Kubernetes page */
router.get('/', function(req, res, next) {
  res.render('kubernetes', { title: 'Kubernetes Pod Listing' });
});

/* API endpoint to list pods in a namespace */
router.post('/api/list-pods', async function(req, res, next) {
  const namespace = req.body.namespace || 'default';
  
  try {
    const pods = await kubernetesService.listPods(namespace);
    res.json({ success: true, pods: pods, namespace: namespace });
  } catch (error) {
    logger.error('Failed to list pods', { namespace, error: error.message });
    next(error);
  }
});

/* API endpoint to list namespaces */
router.get('/api/namespaces', async function(req, res, next) {
  try {
    const namespaces = await kubernetesService.getNamespaces();
    res.json({ success: true, namespaces: namespaces });
  } catch (error) {
    logger.error('Failed to list namespaces', { error: error.message });
    next(error);
  }
});


module.exports = router;