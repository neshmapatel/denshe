class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "DeNshe Jewellery <denshe1713@gmail.com>") }
  layout "mailer"
end
