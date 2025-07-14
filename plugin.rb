# frozen_string_literal: true

# name: salla-discourse
# about: Official Salla integration with Discourse
# version: 1.0.0
# authors: Salla
# url: https://www.salla.sa

after_initialize do
  add_admin_route 'salla.banner.title', 'banner'

  Discourse::Application.routes.append do
    mount ::Salla::Engine, at: '/salla'
    get '/admin/plugins/salla/banner' => 'admin/banners#index', constraints: StaffConstraint.new
  end

  register_asset "javascripts/discourse/templates/components/banner.hbs"
  register_asset "javascripts/discourse/components/banner.js"
  register_asset "stylesheets/banner.scss"

  Api::Application.instance.plugin_outlets.register_outlet('header-after-home-logo', 'banner')
end
