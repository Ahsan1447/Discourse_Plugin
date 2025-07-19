# frozen_string_literal: true

Discourse::Application.routes.append do
  get "/t/:id/increment_count" => "salla_serializers/topics#increment_count"
end
