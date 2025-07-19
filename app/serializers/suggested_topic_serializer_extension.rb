# frozen_string_literal: true

SuggestedTopicSerializer.class_eval do
  attributes :cooked,
             :category,
             :topic_creator,
             :first_post_details,
             :category_topic

	 def cooked
    object&.first_post&.cooked
  end

  def category
    {
      id: object.category.id,
      name: object.category&.name,
      topic_title: object.title,
      only_admin_can_post: object.category&.groups&.exists?(name: "admins"),
      emoji: object.category&.uploaded_logo&.url ? Discourse.base_url_no_prefix + object.category.uploaded_logo.url.to_s : nil
    }
  end

  def topic_creator
    {
      id: object.user&.id,
      username: object.user&.username,
      avatar: object.user&.avatar_template,
      name: object.user&.name
    }
  end

  def first_post_details
    {
      post_id: object&.first_post&.id,
      bookmark_id: bookmark_id_for_first_post,
      is_post_liked: is_post_liked?,
      is_post_bookmarked: is_post_bookmarked?
    }
  end

  def category_topic
    object.is_category_topic?
  end

  private

    def is_post_liked?
      DiscourseReactions::ReactionUser
      .where(user_id: scope.user&.id, post_id: object&.first_post&.id)
      .exists?
    end

    def is_post_bookmarked?
      object&.first_post&.bookmarks&.where(user_id: scope.user&.id)&.last.present?
    end

    def bookmark_id_for_first_post
      bookmark = object&.first_post&.bookmarks&.where(user_id: scope.user&.id).last
      bookmark&.id
    end
end