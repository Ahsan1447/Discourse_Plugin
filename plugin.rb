# frozen_string_literal: true

# name: salla_serializers
# about: Add Salla serializers
# version: 1.0
# authors: Ahsan Afzal
gem "sentry-ruby"
gem "sentry-rails"

enabled_site_setting :salla_serializers_enabled

require 'sentry-ruby'
require 'sentry-rails'

after_initialize do

  %w[
    basic_category_serializer_extension
    post_serializer_extension
    suggested_topic_serializer_extension
    topic_list_item_serializer_extension
  ].each do |file|
    require_relative "app/serializers/#{file}"
  end

  if ENV['SENTRY_DSN'].present?
    ::Sentry.init do |config|
      config.dsn = ENV['SENTRY_DSN']
      config.environment = ENV['SENTRY_ENV'] || 'staging'

      # get breadcrumbs from logs
      config.breadcrumbs_logger = [:active_support_logger, :http_logger]
      # Add data like request headers and IP for users, if applicable;
      # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
      config.send_default_pii = true

      config.traces_sample_rate = 0.1
      config.sample_rate = 0.1

    end
  end


  require_relative "app/controllers/topics_controller.rb"
  load File.expand_path("app/config/routes.rb", __dir__)

  require_relative "lib/salla_serializers/controller_extensions"
  ::ApplicationController.class_eval do
    include ::SallaSerializers::ControllerExtensions
  end

  require_relative "lib/salla_serializers/tags_controller_patch"
  ::TagsController.prepend SallaSerializers::TagsControllerPatch

  require_relative "lib/salla_serializers/middleware_patch"
  ContentSecurityPolicy::Middleware.prepend SallaSerializers::MiddlewarePatch

  require_relative "lib/salla_serializers/email_interceptor"
  ActionMailer::Base.register_interceptor(SallaSerializers::EmailInterceptor)

  require_relative "lib/salla_serializers/auth_cookie_patch"
  ::Auth::DefaultCurrentUserProvider.prepend SallaSerializers::AuthCookiePatch
end
