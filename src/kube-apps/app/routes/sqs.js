var express = require('express');
var router = express.Router();
const { SQSClient, SendMessageCommand, ReceiveMessageCommand, DeleteMessageCommand } = require('@aws-sdk/client-sqs');
const { logger } = require('../middleware/errorHandler');
const { retry } = require('../utils/retry');

// Create SQS client - Using IRSA, credentials are automatically provided
const sqsClient = new SQSClient({
  region: process.env.AWS_REGION || 'eu-central-1',
  maxAttempts: 3,
  retryMode: 'adaptive'
});

/* GET SQS page */
router.get('/', function(req, res, next) {
  res.render('sqs', { 
    title: 'SQS Message Queue',
    queueUrl: process.env.SQS_QUEUE_URL || 'Not configured'
  });
});

/* API endpoint to send a message */
router.post('/api/send-message', async function(req, res, next) {
  const { message } = req.body;
  const queueUrl = process.env.SQS_QUEUE_URL;
  
  if (!queueUrl) {
    const error = new Error('SQS_QUEUE_URL not configured');
    error.status = 500;
    return next(error);
  }
  
  if (!message) {
    const error = new Error('Message is required');
    error.status = 400;
    return next(error);
  }
  
  const command = new SendMessageCommand({
    QueueUrl: queueUrl,
    MessageBody: JSON.stringify({
      message: message,
      timestamp: new Date().toISOString(),
      source: 'web-app'
    }),
    MessageAttributes: {
      'SentAt': {
        DataType: 'String',
        StringValue: new Date().toISOString()
      }
    }
  });
  
  try {
    const result = await retry(async () => {
      return await sqsClient.send(command);
    }, {
      retries: 3,
      delay: 1000,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying SQS sendMessage (attempt ${attempt})`, { error: error.message });
      }
    });
    
    res.json({ 
      success: true, 
      messageId: result.MessageId,
      message: message
    });
  } catch (error) {
    logger.error('Failed to send SQS message', { message, error: error.message });
    next(error);
  }
});

/* API endpoint to receive messages */
router.get('/api/receive-messages', async function(req, res, next) {
  const queueUrl = process.env.SQS_QUEUE_URL;
  
  if (!queueUrl) {
    const error = new Error('SQS_QUEUE_URL not configured');
    error.status = 500;
    return next(error);
  }
  
  const command = new ReceiveMessageCommand({
    QueueUrl: queueUrl,
    MaxNumberOfMessages: 10,
    WaitTimeSeconds: 5,
    MessageAttributeNames: ['All']
  });
  
  try {
    const result = await retry(async () => {
      return await sqsClient.send(command);
    }, {
      retries: 3,
      delay: 1000,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying SQS receiveMessage (attempt ${attempt})`, { error: error.message });
      }
    });
    
    if (!result.Messages || result.Messages.length === 0) {
      return res.json({ 
        success: true, 
        messages: [],
        count: 0
      });
    }
    
    const messages = result.Messages.map(msg => {
      let body;
      try {
        body = JSON.parse(msg.Body);
      } catch (e) {
        body = msg.Body;
      }
      
      return {
        messageId: msg.MessageId,
        receiptHandle: msg.ReceiptHandle,
        body: body,
        attributes: msg.MessageAttributes
      };
    });
    
    res.json({ 
      success: true, 
      messages: messages,
      count: messages.length
    });
  } catch (error) {
    logger.error('Failed to receive SQS messages', { error: error.message });
    next(error);
  }
});

/* API endpoint to delete a message */
router.post('/api/delete-message', async function(req, res, next) {
  const { receiptHandle } = req.body;
  const queueUrl = process.env.SQS_QUEUE_URL;
  
  if (!queueUrl) {
    const error = new Error('SQS_QUEUE_URL not configured');
    error.status = 500;
    return next(error);
  }
  
  if (!receiptHandle) {
    const error = new Error('Receipt handle is required');
    error.status = 400;
    return next(error);
  }
  
  const command = new DeleteMessageCommand({
    QueueUrl: queueUrl,
    ReceiptHandle: receiptHandle
  });
  
  try {
    await retry(async () => {
      return await sqsClient.send(command);
    }, {
      retries: 3,
      delay: 1000,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying SQS deleteMessage (attempt ${attempt})`, { error: error.message });
      }
    });
    
    res.json({ 
      success: true, 
      message: 'Message deleted successfully'
    });
  } catch (error) {
    logger.error('Failed to delete SQS message', { receiptHandle, error: error.message });
    next(error);
  }
});

module.exports = router;