# frozen_string_literal: true

module DiscourseFixedCommunityBanner
  class BannerController < ::ApplicationController
    def show
      # Check if user can see the banner (you can customize this logic)
      if SiteSetting.fixed_community_banner_enabled && SiteSetting.fixed_community_banner_active
        render json: {
          text: SiteSetting.fixed_community_banner_text,
          link: SiteSetting.fixed_community_banner_link,
          cta_text: SiteSetting.fixed_community_banner_cta_text,
          active: SiteSetting.fixed_community_banner_active
        }
      else
        render json: { active: false }
      end
    end
  end
end 