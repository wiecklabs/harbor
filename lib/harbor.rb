require_relative "harbor/core"

config.assets.serve_static = false
config.assets.paths = []

config.locales.default = Harbor::Locale::default

require "harbor/mail/mailer"
require "harbor/mail/servers/sendmail"

config.mailer = Harbor::Mail::Mailer
config.mail_server = Harbor::Mail::Servers::Sendmail

config.console = Harbor::Consoles::IRB
