# Salla Serializers Discourse Plugin

## Overview

**salla_discourse_plugin** is a Discourse plugin that extends and customizes the default serializers, controllers, and middleware to provide additional data and behavior for Salla's community forum integration. It introduces new attributes to various serializers, customizes API responses, and adds/patches endpoints for enhanced forum functionality.

## Features

- **Extended Serializers:**
  - Adds new attributes to `CategoryDetailedSerializer`, `PostSerializer`, `SuggestedTopicSerializer`, and `TopicListItemSerializer`.
  - Includes custom fields such as `can_post`, `emoji`, `topic_creator`, `first_post_details`, and more.
- **Controller Extensions:**
  - Modifies API responses to remove sensitive user data unless accessed by an admin.
  - Adds logic to inject default values into category custom fields for consistent API structure.
- **Custom Middleware Patch:**
  - Ensures API username headers are properly resolved to usernames (not just IDs).
- **Custom Routes and Controllers:**
  - Adds a new endpoint: `GET /t/:id/increment_count` to increment topic view counts.
- **Tag Controller Patch:**
  - Enhances tag filtering options in topic lists: if `tag_names` is provided, topics are filtered by those tags, and `match_all_tags` is supported.
- **Session Cookie Patch:**
  - Adds domain to session cookies for improved SSO/cross-domain support.
- **Email Interceptor:**
  - Rewrites links in outgoing emails to match Salla's frontend URLs.

## Installation

1. Clone or download this repository into your Discourse `plugins` directory:
   ```sh
   git clone <repository-url> plugins/salla_serializers
   ```
2. Rebuild your Discourse application:
   ```sh
   ./launcher rebuild app
   ```

## Configuration

The plugin can be enabled or disabled via site settings:

- **Setting:** `salla_serializers_enabled`
- **Default:** `true`
- **Location:** Admin > Settings > Plugins

## Usage & API Changes

### Affected API Endpoints

- **GET /t/:id/increment_count**
  - Increments the view count for a topic. Used for custom analytics or integrations.
- **Tag Filtering in Topic Lists**
  - When calling topic list endpoints, passing `tag_names` as a parameter will filter topics by those tags. The `match_all_tags` parameter is also supported.
- **All endpoints using the following serializers:**
  - `BasicCategorySerializer`, `PostSerializer`, `SuggestedTopicSerializer`, `TopicListItemSerializer`
  - These serializers now include additional fields:
    - `can_post`: Boolean, true if only current_user can post in the category.
    - `emoji`: URL to a category emoji image.
    - `topic_creator`: Object with user details (id, username, name, avatar).
    - `first_post_details`: Object with first post/bookmark/like info.
    - `cooked`: (where applicable) The cooked HTML of the first post.
    - Other topic/category metadata (views, like_count, posts_count, etc.).

### API Response Filtering
- For non-admin users, API responses will have sensitive user fields (`admin`, `moderator`, `trust_level`, and the `users` key) removed for privacy.
- Category custom fields in API responses will always include default values for `post_view`, `tabs_view`, `user_can_create_post`, and `show_main_post`.

### Session Cookie Patch
- The authentication/session cookie now includes a domain, which may affect SSO or cross-domain authentication. Ensure your environment variables or Discourse settings are configured accordingly.

### Middleware Patch
- The plugin ensures that the `HTTP_API_USERNAME` header is always a username, not just a user ID, for all API requests.

### Email Interceptor
- Outgoing emails have their links rewritten to match Salla's frontend URLs. This does not affect API endpoints directly but may affect user experience.

## Development

- Main plugin logic is in `plugin.rb`.
- Serializer extensions are in `app/serializers/`.
- Controller and middleware patches are in `lib/salla_serializers/`.
- Custom controller is in `app/controllers/`.
- Routes are defined in `app/config/routes.rb`.
- Plugin settings are in `config/settings.yml`.

## Authors
- Ahsan Afzal