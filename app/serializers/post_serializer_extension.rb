# frozen_string_literal: true

PostSerializer.class_eval do
  attributes :category,
             :topic_creator,
             :views,
             :like_count,
             :posts_count,
             :last_posted_at,
             :first_post_details

	def category
		topic = object.topic
		{
			id: topic.category_id,
			name: topic.category.name,
			only_admin_can_post: topic.category.groups.exists?(name: "admins"),
			topic_title: object.topic.title,
      emoji: topic.category&.uploaded_logo ? Discourse.base_url_no_prefix + topic.category.uploaded_logo.url.to_s : nil
		}
	end

	def topic_creator
    {
      id: object.user&.id,
      username: object.user&.username,
      name: object.user&.name,
      avatar: object.user&.avatar_template
    }
  end

  def views
    object.topic&.views
  end

  def like_count
    object.topic&.like_count
  end

  def posts_count
    object.topic&.posts_count
  end

  def last_posted_at
    object.topic&.last_posted_at
  end

  def first_post_details
    {
      post_id: object&.topic&.first_post&.id,
      bookmark_id: bookmark_id_for_first_post,
      is_post_liked: is_post_liked?,
      is_post_bookmarked: is_post_bookmarked?
    }
  end

  def is_post_liked?
    return false unless defined?(DiscourseReactions::ReactionUser)
    
    DiscourseReactions::ReactionUser.where(
      user_id: scope.user&.id,
      post_id: object&.topic&.first_post&.id
    ).exists?
  end

  def is_post_bookmarked?
    object&.topic&.first_post&.bookmarks&.where(user_id: scope.user&.id)&.last.present?
  end

  def bookmark_id_for_first_post
    bookmark = object&.topic&.first_post&.bookmarks&.where(user_id: scope.user&.id).last
    bookmark&.id
  end
end