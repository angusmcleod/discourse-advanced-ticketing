# name: wikimedia-ticketing
# about: Various enhancements to support Wikimedia's ticketing system
# version: 0.0.1
# url: https://github.com/angusmcleod/wikimedia-ticketing
# authors: Angus McLeod

after_initialize do
  module UserNotificationsExtension
    protected def send_notification_email(opts)
      @body_only = opts[:user] && opts[:user].staged
      super(opts)
    end
  end

  module BuildEmailHelperExtension
    def build_email(*builder_args)
      if builder_args[1] && @body_only
        builder_args[1][:body_only] = @body_only
      end
      super(*builder_args)
    end
  end

  require_dependency 'user_notifications'
  class ::UserNotifications
    prepend UserNotificationsExtension
    prepend BuildEmailHelperExtension
  end

  module MessageBuilderExtension
    def html_part
      if @opts[:body_only]
        @opts[:html_override] = @opts[:message]
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

  class Email::MessageBuilder
    prepend MessageBuilderExtension
  end
end
