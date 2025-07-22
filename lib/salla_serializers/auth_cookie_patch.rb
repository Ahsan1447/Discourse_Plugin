# frozen_string_literal: true

module SallaSerializers
  module AuthCookiePatch
    TOKEN_COOKIE = Auth::DefaultCurrentUserProvider::TOKEN_COOKIE

    def set_auth_cookie!(unhashed_auth_token, user, cookie_jar)
      data = {
        token: unhashed_auth_token,
        user_id: user.id,
        username: user.username,
        trust_level: user.trust_level,
        issued_at: Time.zone.now.to_i,
      }

      expires = SiteSetting.maximum_session_age.hours.from_now if SiteSetting.persistent_sessions
      same_site = SiteSetting.same_site_cookies if SiteSetting.same_site_cookies != "Disabled"

      cookie_jar.encrypted[TOKEN_COOKIE] = {
        value: data,
        httponly: true,
        secure: SiteSetting.force_https,
        expires: expires,
        domain: ENV["COOKIE_DOMAIN"] || Discourse.current_hostname,
        same_site: same_site,
      }
    end

    def log_off_user(session, cookie_jar)
      user = current_user

      if SiteSetting.log_out_strict && user
        user.user_auth_tokens.destroy_all

        if user.admin && defined?(Rack::MiniProfiler)
          cookie_jar.delete("__profilin")
        end

        user.logged_out
      elsif user && @user_token
        @user_token.destroy
        DiscourseEvent.trigger(:user_logged_out, user)
      end

      cookie_jar.delete("authentication_data")
      cookie_jar.delete(TOKEN_COOKIE, domain: ENV["COOKIE_DOMAIN"])
    end
  end
end