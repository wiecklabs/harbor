require "logging"

Logging.configure do

  logger 'request' do
    level :info
    appenders 'request'
  end

  logger 'error' do
    level :error
    appenders 'error'
  end

  appender 'request' do
    type 'File'
    filename 'log/request.log'
  end

  appender 'error' do
    type 'File'
    filename 'log/error.log'
  end

end