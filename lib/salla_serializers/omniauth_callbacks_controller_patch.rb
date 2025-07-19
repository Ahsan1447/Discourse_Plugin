# frozen_string_literal: true

module SallaSerializers
  module OmniauthCallbacksControllerPatch
    def complete
      raise Discourse::ReadOnly if @readonly_mode && !@staff_writes_only_mode
      raise Discourse::NotFound unless auth = request.env["omniauth.auth"]

      auth[:session] = session

      authenticator = self.class.find_authenticator(params[:provider])

      if session.delete(:auth_reconnect) && authenticator.can_connect_existing_user? && current_user
        return redirect_to persist_auth_token(auth)
      else
        DiscourseEvent.trigger(:before_auth, authenticator, auth, session, cookies, request)
        @auth_result = authenticator.after_authenticate(auth)
        @auth_result.user = nil if @auth_result&.user&.staged # Treat staged users the same as unregistered users
        DiscourseEvent.trigger(:after_auth, authenticator, @auth_result, session, cookies, request)
      end

      preferred_origin = request.env["omniauth.origin"]

      if session[:destination_url].present?
        preferred_origin = session[:destination_url]
        session.delete(:destination_url)
      elsif SiteSetting.enable_discourse_connect_provider && payload = cookies.delete(:sso_payload)
        preferred_origin = session_sso_provider_url + "?" + payload
      elsif cookies[:destination_url].present?
        preferred_origin = cookies[:destination_url]
        cookies.delete(:destination_url)
      end

      if preferred_origin.present?
        parsed =
          begin
            URI.parse(preferred_origin)
          rescue URI::Error
          end

        if valid_origin?(parsed)
          @origin = +"#{parsed.path}"
          @origin << "?#{parsed.query}" if parsed.query
        end
      end

      @origin = Discourse.base_path("/") if @origin.blank?

      @auth_result.destination_url = @origin
      @auth_result.authenticator_name = authenticator.name

      return render_auth_result_failure if @auth_result.failed?

      raise Discourse::ReadOnly if @staff_writes_only_mode && !@auth_result.user&.staff?

      complete_response_data

      return render_auth_result_failure if @auth_result.failed?

      client_hash = @auth_result.to_client_hash
      if authenticator.can_connect_existing_user? &&
         (SiteSetting.enable_local_logins || Discourse.enabled_authenticators.count > 1)
        # There is more than one login method, and users are allowed to manage associations themselves
        client_hash[:associate_url] = persist_auth_token(auth)
      end

      cookies["_bypass_cache"] = true
      cookies[:authentication_data] = { value: client_hash.to_json, path: Discourse.base_path("/") }



      # Replace the original redirect logic with custom redirect
      redirect_to(
        ENV["OAUTH_REDIRECT_URL"] || "https://community.salla.com/?logged_in_check=true",
        allow_other_host: true
      )
    end
  end
end