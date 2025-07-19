# frozen_string_literal: true

module SallaSerializers
  module SentryConfiguration
    def self.initialize_sentry
      return unless ENV['SENTRY_DSN'].present?

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
  end
end 