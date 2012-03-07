require_relative "harbor/core"

config.locales.default = Harbor::Locale::default

require "harbor/mail/mailer"
require "harbor/mail/servers/sendmail"

config.mailer = Harbor::Mail::Mailer
config.mail_server = Harbor::Mail::Servers::Sendmail