const { logger } = require('../middleware/errorHandler');

async function retry(fn, options = {}) {
  const {
    retries = 3,
    delay = 1000,
    backoff = 2,
    onRetry = () => {}
  } = options;

  let lastError;
  
  for (let i = 0; i < retries; i++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      
      if (i < retries - 1) {
        const waitTime = delay * Math.pow(backoff, i);
        logger.warn(`Retry attempt ${i + 1}/${retries} after ${waitTime}ms`, {
          error: error.message
        });
        
        onRetry(error, i + 1);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
  }
  
  throw lastError;
}

module.exports = { retry };