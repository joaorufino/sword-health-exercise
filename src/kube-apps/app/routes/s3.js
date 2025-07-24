var express = require('express');
var router = express.Router();
const { S3Client, ListBucketsCommand, ListObjectsV2Command, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { logger } = require('../middleware/errorHandler');
const { retry } = require('../utils/retry');

// Create S3 client - Using IRSA, credentials are automatically provided
const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'eu-central-1',
  maxAttempts: 3,
  retryMode: 'adaptive'
});

/* GET S3 page */
router.get('/', function(req, res, next) {
  res.render('s3', { 
    title: 'S3 Bucket Access',
    readOnlyBucket: process.env.S3_READONLY_BUCKET || 'Not configured',
    readWriteBucket: process.env.S3_BUCKET || 'Not configured'
  });
});

/* API endpoint to list buckets */
router.get('/api/list-buckets', async function(req, res, next) {
  try {
    const command = new ListBucketsCommand({});
    
    const data = await retry(async () => {
      return await s3Client.send(command);
    }, {
      retries: 3,
      delay: 1000,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying S3 listBuckets (attempt ${attempt})`, { error: error.message });
      }
    });
    
    const buckets = data.Buckets.map(bucket => ({
      name: bucket.Name,
      creationDate: bucket.CreationDate
    }));
    
    res.json({ success: true, buckets: buckets });
  } catch (error) {
    logger.error('Failed to list S3 buckets', { error: error.message });
    next(error);
  }
});

/* API endpoint to list objects in a bucket */
router.post('/api/list-objects', async function(req, res, next) {
  const bucketName = req.body.bucketName;
  
  if (!bucketName) {
    const error = new Error('Bucket name is required');
    error.status = 400;
    return next(error);
  }
  
  try {
    const command = new ListObjectsV2Command({
      Bucket: bucketName,
      MaxKeys: 100
    });
    
    const data = await retry(async () => {
      return await s3Client.send(command);
    }, {
      retries: 3,
      delay: 1000,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying S3 listObjects (attempt ${attempt})`, { bucketName, error: error.message });
      }
    });
    
    const objects = (data.Contents || []).map(object => ({
      key: object.Key,
      size: formatBytes(object.Size),
      lastModified: object.LastModified,
      storageClass: object.StorageClass
    }));
    
    res.json({ 
      success: true, 
      objects: objects,
      bucketName: bucketName,
      isTruncated: data.IsTruncated
    });
  } catch (error) {
    logger.error('Failed to list S3 objects', { bucketName, error: error.message });
    next(error);
  }
});

/* API endpoint to upload a file to the read-write bucket */
router.post('/api/upload-file', async function(req, res, next) {
  const { fileName, fileContent } = req.body;
  const bucketName = process.env.S3_BUCKET;
  
  if (!bucketName) {
    const error = new Error('S3_BUCKET not configured');
    error.status = 500;
    return next(error);
  }
  
  if (!fileName || !fileContent) {
    const error = new Error('File name and content are required');
    error.status = 400;
    return next(error);
  }
  
  try {
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: fileName,
      Body: fileContent,
      ContentType: 'text/plain'
    });
    
    const data = await retry(async () => {
      return await s3Client.send(command);
    }, {
      retries: 3,
      delay: 1000,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying S3 upload (attempt ${attempt})`, { fileName, error: error.message });
      }
    });
    
    res.json({ 
      success: true, 
      message: 'File uploaded successfully',
      fileName: fileName,
      bucketName: bucketName,
      etag: data.ETag
    });
  } catch (error) {
    logger.error('Failed to upload file to S3', { fileName, bucketName, error: error.message });
    next(error);
  }
});

/* API endpoint to download a file from the read-only bucket */
router.get('/api/download-file/:key', async function(req, res, next) {
  const key = req.params.key;
  const bucketName = process.env.S3_READONLY_BUCKET;
  
  if (!bucketName) {
    const error = new Error('S3_READONLY_BUCKET not configured');
    error.status = 500;
    return next(error);
  }
  
  try {
    const command = new GetObjectCommand({
      Bucket: bucketName,
      Key: key
    });
    
    const data = await retry(async () => {
      return await s3Client.send(command);
    }, {
      retries: 3,
      delay: 1000,
      onRetry: (error, attempt) => {
        logger.warn(`Retrying S3 download (attempt ${attempt})`, { key, error: error.message });
      }
    });
    
    // Convert stream to string
    const streamToString = async (stream) => {
      const chunks = [];
      for await (const chunk of stream) {
        chunks.push(chunk);
      }
      return Buffer.concat(chunks).toString('utf-8');
    };
    
    const content = await streamToString(data.Body);
    
    res.json({ 
      success: true, 
      content: content,
      contentType: data.ContentType,
      metadata: data.Metadata
    });
  } catch (error) {
    logger.error('Failed to download file from S3', { key, bucketName, error: error.message });
    next(error);
  }
});

function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

module.exports = router;