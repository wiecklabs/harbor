require_relative "harbor/core"

config.assets = Harbor::Assets.new
config.helpers = Harbor::ViewHelpers.new
config.locales.default = Harbor::Locale::default

require "harbor/mail/mailer"
require "harbor/mail/servers/sendmail"

config.mailer = Harbor::Mail::Mailer
config.mail_server = Harbor::Mail::Servers::Sendmail

config.console = Harbor::Consoles::IRB
