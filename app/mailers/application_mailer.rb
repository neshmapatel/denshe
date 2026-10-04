class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "DeNshe Jewellery <hello@denshe.in>") }
  layout "mailer"
end
