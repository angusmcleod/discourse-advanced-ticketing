require_dependency 'email/sender'

module Jobs
  class ForwardEmail < Jobs::Base
    sidekiq_options queue: 'critical'

    def execute(args)
      if post = Post.find_by(id: args[:post_id])
        if args[:forwarding_user] = User.find_by(id: args[:user_id])
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
          args[:post_id] = post.id
          args[:topic_id] = post.topic.id

          message = TicketingMailer.forward_email(args)

          recipient_user = add_recipient_user(args[:email], args[:forwarding_user], post.topic)

          Email::Sender.new(message, :forward_email, recipient_user).send
        end
      end
    end

    protected

    def add_recipient_user(recipient_email, forwarding_user, topic)
      recipient_user = User.find_by_email(recipient_email)

      if !recipient_user
        recipient_user = User.create!(
          email: recipient_email,
          username: UserNameSuggester.suggest(recipient_email),
          name: User.suggest_name(recipient_email),
          staged: true
        )
      end

      Topic.transaction do
        topic.topic_allowed_users.create!(user_id: recipient_user.id) unless topic.topic_allowed_users.exists?(user_id: recipient_user.id)
        topic.add_small_action(forwarding_user, "forwarded_to", recipient_user.username)
      end

      recipient_user
    end
  end
end
