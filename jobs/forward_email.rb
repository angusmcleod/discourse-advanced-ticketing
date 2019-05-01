require_dependency 'email/sender'

module Jobs
  class ForwardEmail < Jobs::Base
    sidekiq_options queue: 'critical'

    def execute(args)
      if args[:post] = Post.find_by(id: args[:post_id])
        if args[:user] = User.find_by(id: args[:user_id])
          message = TicketingMailer.forward_email(args)
          Email::Sender.new(message, :forward_email).send
        end
      end
    end
  end
end
