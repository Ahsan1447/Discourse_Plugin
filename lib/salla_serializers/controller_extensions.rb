# frozen_string_literal: true

module SallaSerializers
  module ControllerExtensions
    def self.included(base)
      base.after_action :remove_users_from_response
      base.before_action :set_sentry_context
    end

    private

    def remove_users_from_response
			return if admin_referer?
			return if %w(search_users).include?(action_name)

			body = JSON.parse(response.body) rescue return
			body.delete("users")

			body = deep_reject_keys(body, ["admin", "moderator", "trust_level"])
			response.body = body.to_json
    end

    def deep_reject_keys(hash, keys_to_reject)
			return hash if controller_path == 'users' && action_name == 'show'

			case hash
			when Hash
				hash.each_with_object({}) do |(k, v), new_hash|
						new_hash[k] = deep_reject_keys(v, keys_to_reject) unless keys_to_reject.include?(k.to_s)
				end
			when Array
					hash.map { |v| deep_reject_keys(v, keys_to_reject) }
				else
					hash
				end
    end

		def admin_referer?
			request.referer&.match?(%r{/forum/admin(/.*)?$})
		end

		def set_sentry_context
			if current_user
				::Sentry.set_user(
					id: current_user.id,
					username: current_user.username,
					email: current_user.email,
					ip_address: request.remote_ip
				)
			end
		rescue => e
			Rails.logger.error("Failed to set Sentry context: #{e.message}\n#{e.backtrace.join("\n")}")
		end
  end
end