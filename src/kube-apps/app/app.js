require('dotenv').config();

var express = require('express');
var path = require('path');
var favicon = require('serve-favicon');
var morgan = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var lessMiddleware = require('less-middleware');
var { testConnection, initializeDatabase } = require('./config/database');
var { errorHandler, logger } = require('./middleware/errorHandler');

// Initialize database connection with error handling
testConnection().catch(err => {
  logger.error('Failed to connect to database', { error: err.message });
});
initializeDatabase().catch(err => {
  logger.error('Failed to initialize database', { error: err.message });
});

var index = require('./routes/index');
var users = require('./routes/users');
var kubernetes = require('./routes/kubernetes');
var s3 = require('./routes/s3');
var sqs = require('./routes/sqs');
var health = require('./routes/health');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

// uncomment after placing your favicon in /public
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(morgan('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(lessMiddleware(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', index);
app.use('/users', users);
app.use('/kubernetes', kubernetes);
app.use('/s3', s3);
app.use('/sqs', sqs);
app.use('/', health);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use(errorHandler);

module.exports = app;
