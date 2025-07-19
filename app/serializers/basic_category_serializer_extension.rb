# frozen_string_literal: true

CategoryDetailedSerializer.class_eval do
  attributes :can_post

  def can_post
    return false unless scope.user

    # Use Discourse's built-in category permission system
    Guardian.new(scope.user).can_create_topic_on_category?(object)

  end
end