const k8s = require('@kubernetes/client-node');
const { retry } = require('../utils/retry');
const { logger } = require('../middleware/errorHandler');

class KubernetesService {
  constructor() {
    this.kc = new k8s.KubeConfig();
    this.isConfigured = false;
    
    this.loadConfig();
  }

  loadConfig() {
    try {
      if (process.env.KUBECONFIG) {
        this.kc.loadFromFile(process.env.KUBECONFIG);
      } else {
        this.kc.loadFromCluster();
      }
      this.k8sApi = this.kc.makeApiClient(k8s.CoreV1Api);
      this.isConfigured = true;
      logger.info('Kubernetes client configured successfully');
    } catch (err) {
      logger.error('Failed to load Kubernetes config:', err);
      this.isConfigured = false;
    }
  }

  async listPods(namespace = 'default') {
    if (!this.isConfigured) {
      throw new Error('Kubernetes client not configured');
    }

    return retry(async () => {
      const response = await this.k8sApi.listNamespacedPod(namespace);
      return response.body.items.map(pod => ({
        name: pod.metadata.name,
        namespace: pod.metadata.namespace,
        status: pod.status.phase,
        ready: this.getPodReadiness(pod),
        restarts: this.getPodRestarts(pod),
        age: this.getAge(pod.metadata.creationTimestamp),
        conditions: pod.status.conditions || []
      }));
    }, {
      retries: 3,
      delay: 1000,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying Kubernetes API call (attempt ${attempt})`, {
          namespace,
          error: error.message
        });
      }
    });
  }

  async getNamespaces() {
    if (!this.isConfigured) {
      throw new Error('Kubernetes client not configured');
    }

    return retry(async () => {
      const response = await this.k8sApi.listNamespace();
      return response.body.items.map(ns => ({
        name: ns.metadata.name,
        status: ns.status.phase
      }));
    });
  }

  getPodReadiness(pod) {
    if (!pod.status.containerStatuses) {
      return '0/0';
    }
    const ready = pod.status.containerStatuses.filter(c => c.ready).length;
    const total = pod.status.containerStatuses.length;
    return `${ready}/${total}`;
  }

  getPodRestarts(pod) {
    if (!pod.status.containerStatuses) {
      return 0;
    }
    return pod.status.containerStatuses.reduce((sum, c) => sum + c.restartCount, 0);
  }

  getAge(timestamp) {
    const created = new Date(timestamp);
    const now = new Date();
    const diff = now - created;
    
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    if (days > 0) return `${days}d${hours}h`;
    if (hours > 0) return `${hours}h${minutes}m`;
    return `${minutes}m`;
  }

  isHealthy() {
    return this.isConfigured;
  }
}

module.exports = new KubernetesService();