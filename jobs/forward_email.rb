require_dependency 'email/sender'

module Jobs
  class ForwardEmail < Jobs::Base
    sidekiq_options queue: 'critical'

    def execute(args)
      if post = Post.find_by(id: args[:post_id])
        if args[:user] = User.find_by(id: args[:user_id])
          body = ''

          if post.post_number > 1 && args[:include_prior]
            post_numbers = (1..(post.post_number)).to_a
            post_numbers.each do |post_number|
              if prior_post = Post.find_by(topic_id: post.topic_id, post_number: post_number)
                if user = User.find_by(id: post.user_id)
                  body += "From " + user.email + "\n\n"
                end

                body += prior_post.raw

                if post_number != post.post_number
                  body += "\n\n<hr>\n\n"
                end
              end
            end
          else
            if user = User.find_by(id: post.user_id)
              body += "From " + user.email + "\n\n"
            end

            body += post.raw
          end

          group = Group.find_by(id: args[:group_id])

          if group && group.incoming_email
            args[:from] = group.incoming_email
          end

          args[:title] = post.topic.title
          args[:body] = body

          message = TicketingMailer.forward_email(args)

          Email::Sender.new(message, :forward_email).send
        end
      end
    end
  end
end
