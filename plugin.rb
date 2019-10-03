# name: discourse-advanced-ticketing
# about: Various enhancements to support using Discourse as a ticketing system
# version: 0.0.1
# url: https://github.com/angusmcleod/discourse-advanced-ticketing
# authors: Angus McLeod

after_initialize do
  load File.expand_path('../jobs/forward_email.rb', __FILE__)
  load File.expand_path('../mailers/ticketing_mailer.rb', __FILE__)

  module ::AdvancedTicketing
    class Engine < ::Rails::Engine
      engine_name "advanced_ticketing"
      isolate_namespace AdvancedTicketing
    end
  end

  Discourse::Application.routes.append do
    mount ::AdvancedTicketing::Engine, at: "ticketing"
  end

  AdvancedTicketing::Engine.routes.draw do
    post "forward" => "ticketing#forward"
  end

  class AdvancedTicketing::TicketingController < ::ApplicationController
    def forward
      args = params.permit(:email, :message, :post_id, :include_prior, :group_id, :hide_responses).to_h
      args[:user_id] = current_user.id

      begin
        Jobs::ForwardEmail.new.execute(args)
        render json: success_json
      rescue => e
        render json: { error: e }, status: 422
      end
    end
  end
  
  Group.register_custom_field_type('advanced_ticketing_plain_text_notifications', :boolean)
  Group.preloaded_custom_fields << "advanced_ticketing_plain_text_notifications" if Group.respond_to? :preloaded_custom_fields

  module AdminGroupsControllerAdvancedTicketingExtension
    private def group_params
      group = params.require(:group).permit(:plain_text_notifications)

      if group[:plain_text_notifications] != nil
        super.merge(custom_fields: {
          advanced_ticketing_plain_text_notifications: group[:plain_text_notifications]
        })
      else
        super
      end
    end
  end

  module GroupsControllerAdvancedTicketingExtension
    private def group_params(automatic: false)
      group = params.require(:group).permit(:plain_text_notifications)

      if group[:plain_text_notifications] != nil
        super.merge(custom_fields: {
          advanced_ticketing_plain_text_notifications: group[:plain_text_notifications]
        })
      else
        super
      end
    end
  end

  require_dependency 'admin/groups_controller'
  class ::Admin::GroupsController
    prepend AdminGroupsControllerAdvancedTicketingExtension
  end

  require_dependency 'groups_controller'
  class ::GroupsController
    prepend GroupsControllerAdvancedTicketingExtension
  end

  module UserNotificationsAdvancedTicketingExtension
    protected def send_notification_email(opts)
      user = opts[:user]
      topic = opts[:post]&.topic
            
      @body_only = topic&.private_message? &&
         topic.allowed_groups.any? &&
         topic.allowed_groups.first.custom_fields['advanced_ticketing_plain_text_notifications'] &&
         user&.staged
      
      super(opts)
    end
  end

  module BuildEmailHelperAdvancedTicketingExtension
    def build_email(*builder_args)
      if builder_args[1] && @body_only
        builder_args[1][:body_only] = @body_only
      end
      super(*builder_args)
    end
  end

  class ::UserNotifications
    prepend UserNotificationsAdvancedTicketingExtension
    prepend BuildEmailHelperAdvancedTicketingExtension
  end

  module MessageBuilderAdvancedTicketingExtension
    def html_part
      if @opts[:body_only]
        @opts[:html_override] = @opts[:message].gsub(/(?:\n\r?|\r\n?)/, '<br>')
      end
      super
    end

    def body
      if @opts[:body_only]
        @opts[:message]
      else
        super
      end
    end
  end

  class ::Email::MessageBuilder
    prepend MessageBuilderAdvancedTicketingExtension
  end

  module GroupMessagesAdvancedTicketingExtension
    def private_messages_for(user, type)
      if type == :group
        limit = @options[:limit]
        @options[:limit] = false
        page = @options[:page]
        @options[:page] = nil
      end

      result = super(user, type)

      if type == :group
        result = result.joins("LEFT JOIN topic_custom_fields AS tcf ON (tcf.topic_id = topics.id AND tcf.name = 'assigned_to_id')")
          .joins("LEFT JOIN users ON tcf.value::integer = users.id")
          .reorder("
            topics.posts_count,
            CASE WHEN tcf.value IS NULL THEN 1 WHEN tcf.value IS NOT NULL THEN 2 ELSE 3 END,
            CASE WHEN tcf.value IS NULL THEN topics.bumped_at END,
            CASE WHEN tcf.value IS NOT NULL THEN users.username END
          ")

        result = result.limit(@options[:per_page]) unless limit == false

        if page
          offset = page.to_i * options[:per_page]
          result = result.offset(offset) if offset > 0
        end
      end

      result
    end
  end

  require_dependency 'topic_query'
  class ::TopicQuery
    prepend GroupMessagesAdvancedTicketingExtension
  end
  
  SiteSetting.enable_whispers = true
  register_user_custom_field_type('advanced_ticketing_hide_responses', :integer)

  module EmailReceiverAdvancedTicketingExtension
    def create_reply(options = {})      
      if options[:topic] &&
         options[:user] &&
         options[:user].custom_fields['advanced_ticketing_hide_responses'].present? &&
         [*options[:user].custom_fields['advanced_ticketing_hide_responses']].include?(options[:topic].id)
         options[:post_type] = Post.types[:whisper]
      end
      super(options)
    end
  end
  
  require_dependency 'email/receiver'
  class ::Email::Receiver
     prepend EmailReceiverAdvancedTicketingExtension
  end
end
