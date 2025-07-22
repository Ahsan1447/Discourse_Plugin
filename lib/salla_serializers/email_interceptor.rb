# frozen_string_literal: true

module SallaSerializers
  class EmailInterceptor
    ASSET_EXTENSIONS = %w[jpg jpeg png gif svg webp css js ico mp4 mp3 woff woff2 ttf otf].freeze

    def self.delivering_email(message)
      if message.html_part
        html = message.html_part.body.decoded
        sanitized_html = sanitize_links(html)

        message.html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body sanitized_html
        end
      end

      if message.text_part
        text = message.text_part.body.decoded
        sanitized_text = sanitize_links(text)

        message.text_part = Mail::Part.new do
          content_type 'text/plain; charset=UTF-8'
          body sanitized_text
        end
      elsif message.body
        message.body = sanitize_links(message.body.decoded)
      end
    end

    def self.sanitize_links(content)
      return content unless content

      from_url = ENV["REWRITE_FROM_URL"]&.chomp("/")
      to_url = ENV["REWRITE_TO_URL"]&.chomp("/")

      return content unless from_url.present? && to_url.present?

      asset_pattern = /(?:https?:\/\/|\/)[^\s"']+\.(#{ASSET_EXTENSIONS.join('|')})(\?[^\s"']*)?/

      content = content.gsub(%r{(#{Regexp.escape(from_url)}[^\s"'<>]*)}) do |url|
        # Skip URLs containing /email/unsubscribe/
        next url if url.include?('/email/unsubscribe/')

        # Skip if it's an asset URL
        next url if url.match?(asset_pattern)

        # Replace from_url with to_url
        url.sub(from_url, to_url)
      end

      content = content.gsub(%r{(?<!#{Regexp.escape(from_url)})/t/([^\s"'<>]+)(?![^"'\s>]*#{asset_pattern})}) do
        "/detail/#{$1}"
      end

      # Rewrite full user profile URLs like https://community.salla.com/u/{username}
      content = content.gsub(%r{(https?://[^"'<>]+?)/u/([a-zA-Z0-9_\-]+)}) do
        "#{$1}/profile?username=#{$2}"
      end

      # Rewrite full /c/all-groups to /category-detail
      content = content.gsub(%r{(https?://[^"'<>]+?)/c/all-groups}) do
        "#{$1}/category-detail"
      end

      # Remove extra path segments after the ID in detail URLs and trailing slash
      content = content.gsub(%r{(/detail/[^/\s"'<>]+/\d+)(?:/[^/"'\s<>]+)*|(/detail/[^/\s"'<>]+/\d+)/+(?=[?"#'\s>]|$)}) do
        $1 || $2
      end

      content
    end
  end
end