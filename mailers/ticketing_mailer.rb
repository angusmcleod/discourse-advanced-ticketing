require_dependency 'email/message_builder'

class TicketingMailer < ActionMailer::Base
  include Email::BuildEmailHelper

  def forward_email(args)
    build_email(
      args[:email],
      from: args[:from],
      template: 'forward_mailer',
      title: args[:title],
      user_email: args[:user].email,
      message: args[:message],
      body: args[:body]
    )
  end
end
