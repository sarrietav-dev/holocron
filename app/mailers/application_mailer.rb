class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "holocron@localhost") }
  layout "mailer"
end
