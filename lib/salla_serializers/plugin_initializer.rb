# frozen_string_literal: true

module SallaSerializers
  module PluginInitializer
    def self.load_serializers
      %w[
        basic_category_serializer_extension
        post_serializer_extension
        suggested_topic_serializer_extension
        topic_list_item_serializer_extension
      ].each do |file|
        require_relative "../../app/serializers/#{file}"
      end
    end

    def self.load_patches_and_extensions
      # Load topic query patch
      require_relative "../topic_query_patch"

      # Load and apply controller extensions
      require_relative "controller_extensions"
      ::ApplicationController.class_eval do
        include ::SallaSerializers::ControllerExtensions
      end

      # Load and apply various controller patches
      require_relative "tags_controller_patch"
      ::TagsController.prepend SallaSerializers::TagsControllerPatch

      require_relative "middleware_patch"
      ContentSecurityPolicy::Middleware.prepend SallaSerializers::MiddlewarePatch

      require_relative "auth_cookie_patch"
      ::Auth::DefaultCurrentUserProvider.prepend SallaSerializers::AuthCookiePatch

      require_relative "omniauth_callbacks_controller_patch"
      ::Users::OmniauthCallbacksController.prepend SallaSerializers::OmniauthCallbacksControllerPatch

      # Apply categories controller patch
      require_relative "categories_controller_patch"
      ::CategoriesController.include SallaSerializers::CategoriesControllerPatch
    end

    def self.load_email_interceptor
      require_relative "email_interceptor"
      ActionMailer::Base.register_interceptor(SallaSerializers::EmailInterceptor)
    end

    def self.load_discourse_reactions_patch
      require_relative "discourse_reactions_controller_patch"
      if defined?(DiscourseReactions::CustomReactionsController)
        DiscourseReactions::CustomReactionsController.prepend SallaSerializers::DiscourseReactionsControllerPatch
      end
    end

    def self.load_controllers_and_routes
      require_relative "../../app/controllers/topics_controller.rb"
      load File.expand_path("../../app/config/routes.rb", __dir__)

      # Load banner controller
      require_relative "banner_controller"

      # Add the banner route
      Discourse::Application.routes.append do
        get '/banner' => 'discourse_fixed_community_banner/banner#show'
      end
    end
  end
end 