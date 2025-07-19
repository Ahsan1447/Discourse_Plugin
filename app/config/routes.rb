# frozen_string_literal: true

Discourse::Application.routes.append do
  get "/t/:id/increment_count" => "salla_serializers/topics#increment_count"
  get "/count" => "notification_counts#count", :constraints => {format: /(json|rss)/,}
  post "/activity_count" => "notification_counts#activity_count", :constraints => {format: /(json|rss)/,}
end
