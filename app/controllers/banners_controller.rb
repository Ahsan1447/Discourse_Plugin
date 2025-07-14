class BannersController < ApplicationController
  def index
    @banner = Banner.last
    render json: @banner
  end
end