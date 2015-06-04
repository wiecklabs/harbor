require "logging"
require "harbor/logging/request_logger"

Logging.configure do

  logger 'root' do
    level :debug
    appenders 'app'
  end

  logger 'request' do
    additive false
    level :info
    appenders 'request'
  end

  logger 'error' do
    additive false
    level :error
    appenders 'error'
  end

  logger 'bad-request' do
    additive false
    level :error
    appenders 'error'
  end

  appender 'app' do
    type 'File'
    filename 'log/app.log'
  end

  appender 'request' do
    type 'File'
    filename 'log/request.log'
  end

  appender 'error' do
    type 'File'
    layout :type => 'Pattern', :pattern => '[%d] %-5l %c: %m\n', :date_pattern => "%Y-%m-%d %H:%M:%S %z"
    filename 'log/error.log'
  end

end