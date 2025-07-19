# frozen_string_literal: true

TopicListItemSerializer.class_eval do
  attributes :category,
             :topic_creator,
             :cooked,
             :first_post_details,
						 :category_topic
	def category
    {
      id: category_id,
      name: object.category&.name,
      only_admin_can_post: object.category&.groups&.exists?(name: "admins"),
			emoji: object.category&.uploaded_logo ? Discourse.base_url_no_prefix + object.category.uploaded_logo.url.to_s : nil
    }
  end

  def topic_creator
    {
      id: object.user&.id,
      username: object.user&.username,
      avatar: object.user&.avatar_template,
      topic_title: object.title,
      name: object.user&.name
    }
  end

	def cooked
    object&.first_post&.cooked
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
			return false unless defined?(DiscourseReactions::ReactionUser)
			
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