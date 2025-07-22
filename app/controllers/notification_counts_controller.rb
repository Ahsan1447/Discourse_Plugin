# frozen_string_literal: true

module SallaDiscoursePlugin
  class NotificationCountsController < ::ApplicationController
    skip_before_action :verify_authenticity_token, only: :activity_count

    def count
      user_id = params[:user_id]
      notification_types = {
        replied: 1,
        mentioned: 2,
        liked: 5,
        reaction: 25
      }
  
      notifications = Notification
                        .where(user_id: user_id, notification_type: notification_types.values)
                        .group(:notification_type)
                        .count
      notification_counts = notification_types.transform_values { |type| notifications[type] || 0 }
  
      render json: {
        all: notification_counts.values.sum,
        replies: notification_counts[:replied],
        mentions: notification_counts[:mentioned],
        likes_and_reactions: notification_counts[:liked] + notification_counts[:reaction]
      }
    end
  
    def activity_count
      user = User.find_by_username(params[:username])
  
      return render json: { error: 'User not found' }, status: :not_found unless user
  
      activity_data = {
        all: user.user_actions.where(action_type: [5, 4]).count do |action|
          topic = action.target_topic
          topic&.closed == false && topic&.deleted_at.nil?
        end,
        topics: user.topics
                 .select { |topic| topic.closed == false && topic.deleted_at.nil? }.count,
        posts: user.user_actions
        .joins("INNER JOIN topics ON topics.id = user_actions.target_topic_id")
        .where(action_type: 5, "topics.closed": false, "topics.deleted_at": nil)
        .count,
        likes: defined?(DiscourseReactions::ReactionUser) ? DiscourseReactions::ReactionUser.where(user_id: user.id).count : 0,
        answers: defined?(DiscourseSolved) ? user.topics.select {  |t| t.closed == false && t.deleted_at.nil? && t.custom_fields[::DiscourseSolved::ACCEPTED_ANSWER_POST_ID_CUSTOM_FIELD].present? }.count : 0,
        bookmarks: user.bookmarks.where(bookmarkable_type: "Post").count do |bookmark|
          topic = bookmark.bookmarkable
          topic&.deleted_at.nil?
        end,
        avatar_template: user.avatar_template,
        bio: user.user_profile.bio_raw,
        name: user.name,
        username: user.username,
        website: user.user_profile.website,
        custom_fields: user.user_fields
      }
  
      render json: activity_data
    end
  end
end