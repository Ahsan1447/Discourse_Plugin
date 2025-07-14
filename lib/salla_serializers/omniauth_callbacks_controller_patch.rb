# frozen_string_literal: true

module SallaSerializers
  module OmniauthCallbacksControllerPatch
    def complete
      # Replace the original redirect logic with custom redirect
      redirect_to(
        ENV["OAUTH_REDIRECT_URL"] || "https://community.salla.com/?logged_in_check=true",
        allow_other_host: true
      )
    end
  end
end 