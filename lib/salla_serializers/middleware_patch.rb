# frozen_string_literal: true

module SallaSerializers
  module MiddlewarePatch
    def call(env)
      user = User.find_by(id: env["HTTP_API_USERNAME"].to_i)
      if user
        env["HTTP_API_USERNAME"] = user.username
      end

      super(env)
    end
  end
end