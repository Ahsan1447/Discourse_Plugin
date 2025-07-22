# frozen_string_literal: true

# name: Discourse_Plugin
# about: Merged plugin for Salla Community APIs and custom serializers
# version: 1.1
# authors: Ahsan Afzal

gem "sentry-ruby", "5.11.0"
gem "sentry-rails", "5.11.0"

enabled_site_setting :salla_serializers_enabled
enabled_site_setting :fixed_community_banner_enabled
enabled_site_setting :category_custom_field_enabled
enabled_site_setting :enable_salla_community
register_asset 'stylesheets/common.scss'
require 'sentry-ruby'
require 'sentry-rails'

after_initialize do
  # === SALLA COMMUNITY MODULE (from salla-community plugin) ===
  module ::SallaDiscoursePlugin
    PLUGIN_NAME = "Discourse_Plugin".freeze

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace SallaDiscoursePlugin
    end
  end

  # Load notification counts controller in the correct module context
  require_relative "app/controllers/notification_counts_controller"

  # Set up SallaDiscoursePlugin routes
  ::SallaDiscoursePlugin::Engine.routes.draw do
    get "/count" => "notification_counts#count", :constraints => {format: /(json|rss)/,}
    post "/activity_count" => "notification_counts#activity_count", :constraints => {format: /(json|rss)/,}
  end

  # Mount SallaDiscoursePlugin engine
  Discourse::Application.routes.append { mount ::SallaDiscoursePlugin::Engine, at: "/notification_counts" }
  
  # Add cookie store patch
  require_dependency 'action_dispatch/session/discourse_cookie_store'

  module DiscourseCookieStorePatch
    private
    def set_cookie(request, session_id, cookie)
      if Hash === cookie
        cookie[:secure] = true if SiteSetting.force_https
        unless SiteSetting.same_site_cookies == "Disabled"
          cookie[:same_site] = SiteSetting.same_site_cookies
        end
      end
      cookie[:domain] = ENV["COOKIE_DOMAIN"]
      cookie[:path] = "/"
      cookie_jar(request)[@key] = cookie
    end
  end

  ActionDispatch::Session::DiscourseCookieStore.prepend(DiscourseCookieStorePatch)

  # === SALLA SERIALIZERS FUNCTIONALITY (original plugin) ===
  CUSTOM_FIELDS = {
    'post_view' => { type: :string, choices: ['grid', 'list'], default: 'list' },
    'tabs_view' => { type: :boolean, default: true },
    'user_can_create_post' => { type: :boolean, default: true },
    'show_main_post' => { type: :boolean, default: false }
  }

  # Load all extracted modules
  require_relative "lib/salla_serializers/sentry_configuration"
  require_relative "lib/salla_serializers/custom_fields_manager"
  require_relative "lib/salla_serializers/plugin_initializer"


  # Initialize Sentry
  SallaSerializers::SentryConfiguration.initialize_sentry

  # Load serializers
  SallaSerializers::PluginInitializer.load_serializers

  # Load patches and extensions
  SallaSerializers::PluginInitializer.load_patches_and_extensions

  # Load email interceptor
  SallaSerializers::PluginInitializer.load_email_interceptor

  require_relative "app/controllers/topics_controller.rb"
  load File.expand_path("app/config/routes.rb", __dir__)
  # Load Discourse Reactions patch if available
  SallaSerializers::PluginInitializer.load_discourse_reactions_patch

  # Load controllers and routes
  SallaSerializers::PluginInitializer.load_controllers_and_routes

  # Register custom field types
  CUSTOM_FIELDS.each do |field_name, config|
    register_category_custom_field_type(field_name, config[:type])
  end

  # Initialize custom fields - add getter and setter methods to Category class
  CUSTOM_FIELDS.each do |field_name, config|
    # Add getter method with proper boolean conversion and defaults
    add_to_class(:category, field_name.to_sym) do
      value = custom_fields[field_name]
      if config[:type] == :boolean
        # Convert string boolean to actual boolean, with default fallback
        if value.nil?
          config[:default]
        else
          value == "t" || value == true
        end
      else
        # Return default if value is nil
        value.nil? ? config[:default] : value
      end
    end

    # Add setter method - ensure false values are stored as "f"
    add_to_class(:category, "#{field_name}=") do |value|
      if config[:type] == :boolean
        # Always store boolean values as strings, even when false
        # This ensures false values are preserved and not removed
        custom_fields[field_name] = value ? "t" : "f"
      else
        # For non-boolean fields, store the value as-is
        custom_fields[field_name] = value
      end
    end
  end

  # Set defaults for new categories
  on(:category_created) do |category|
    CUSTOM_FIELDS.each do |field_name, config|
      if category.custom_fields[field_name].nil?
        if config[:type] == :boolean
          category.custom_fields[field_name] = config[:default] ? "t" : "f"
        else
          category.custom_fields[field_name] = config[:default]
        end
        category.save_custom_fields
      end
    end
  end

  # Preload all custom fields
  CUSTOM_FIELDS.keys.each do |field_name|
    Site.preloaded_category_custom_fields << field_name
  end

  # Add to serializers
  CUSTOM_FIELDS.keys.each do |field_name|
    add_to_serializer(:site_category, field_name.to_sym) do
      object.send(field_name)
    end
  end
end