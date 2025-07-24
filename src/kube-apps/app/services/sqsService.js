const { SQSClient, SendMessageCommand, ReceiveMessageCommand, DeleteMessageCommand } = require('@aws-sdk/client-sqs');

// Create SQS client - Using IRSA, credentials are automatically provided
const sqsClient = new SQSClient({
  region: process.env.AWS_REGION || 'eu-central-1'
});

// Queue URL from environment variable
const QUEUE_URL = process.env.SQS_QUEUE_URL;

class SQSService {
  /**
   * Send a message to the SQS queue
   * @param {Object} messageData - The message data to send
   * @returns {Promise} - Promise resolving to the SQS response
   */
  async sendMessage(messageData) {
    if (!QUEUE_URL) {
      throw new Error('SQS_QUEUE_URL environment variable is not set');
    }

    const command = new SendMessageCommand({
      QueueUrl: QUEUE_URL,
      MessageBody: JSON.stringify(messageData),
      MessageAttributes: {
        timestamp: {
          DataType: 'String',
          StringValue: new Date().toISOString()
        }
      }
    });

    try {
      const result = await sqsClient.send(command);
      console.log('Message sent successfully:', result.MessageId);
      return result;
    } catch (error) {
      console.error('Error sending message to SQS:', error);
      throw error;
    }
  }

  /**
   * Receive messages from the SQS queue
   * @param {number} maxMessages - Maximum number of messages to receive (1-10)
   * @returns {Promise} - Promise resolving to array of messages
   */
  async receiveMessages(maxMessages = 1) {
    if (!QUEUE_URL) {
      throw new Error('SQS_QUEUE_URL environment variable is not set');
    }

    const command = new ReceiveMessageCommand({
      QueueUrl: QUEUE_URL,
      MaxNumberOfMessages: Math.min(maxMessages, 10),
      WaitTimeSeconds: 20, // Long polling
      MessageAttributeNames: ['All']
    });

    try {
      const result = await sqsClient.send(command);
      if (result.Messages && result.Messages.length > 0) {
        console.log(`Received ${result.Messages.length} messages`);
        return result.Messages;
      }
      return [];
    } catch (error) {
      console.error('Error receiving messages from SQS:', error);
      throw error;
    }
  }

  /**
   * Delete a message from the SQS queue
   * @param {string} receiptHandle - The receipt handle of the message to delete
   * @returns {Promise} - Promise resolving to the SQS response
   */
  async deleteMessage(receiptHandle) {
    if (!QUEUE_URL) {
      throw new Error('SQS_QUEUE_URL environment variable is not set');
    }

    const command = new DeleteMessageCommand({
      QueueUrl: QUEUE_URL,
      ReceiptHandle: receiptHandle
    });

    try {
      const result = await sqsClient.send(command);
      console.log('Message deleted successfully');
      return result;
    } catch (error) {
      console.error('Error deleting message from SQS:', error);
      throw error;
    }
  }

  /**
   * Process messages (receive, handle, and delete)
   * @param {Function} messageHandler - Function to process each message
   * @param {number} maxMessages - Maximum number of messages to process
   * @returns {Promise} - Promise resolving when processing is complete
   */
  async processMessages(messageHandler, maxMessages = 1) {
    try {
      const messages = await this.receiveMessages(maxMessages);
      
      for (const message of messages) {
        try {
          // Parse the message body
          const messageData = JSON.parse(message.Body);
          
          // Process the message
          await messageHandler(messageData, message);
          
          // Delete the message after successful processing
          await this.deleteMessage(message.ReceiptHandle);
        } catch (error) {
          console.error('Error processing message:', error);
          // Don't delete the message if processing failed
        }
      }
      
      return messages.length;
    } catch (error) {
      console.error('Error in processMessages:', error);
      throw error;
    }
  }
}

module.exports = new SQSService();