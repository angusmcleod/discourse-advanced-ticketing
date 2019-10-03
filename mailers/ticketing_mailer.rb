require_dependency 'email/message_builder'

class TicketingMailer < ::ActionMailer::Base
  include ::Email::BuildEmailHelper

  def forward_email(args)
    build_email(
      args[:email],
      from: args[:from],
      template: 'forward_mailer',
      title: args[:title],
      forwarding_user_email: args[:forwarding_user].email,
      message: args[:message],
      body: args[:body],
      post_id: args[:post_id],
      topic_id: args[:topic_id],
      allow_reply_by_email: true
    )
  end
end
