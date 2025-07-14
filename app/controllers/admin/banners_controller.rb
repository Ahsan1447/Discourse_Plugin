class Admin::BannersController < Admin::AdminController
  def index
    @banners = Banner.all
  end

  def create
    @banner = Banner.new(banner_params)
    if @banner.save
      render json: @banner
    else
      render json: { errors: @banner.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @banner = Banner.find(params[:id])
    if @banner.update(banner_params)
      render json: @banner
    else
      render json: { errors: @banner.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @banner = Banner.find(params[:id])
    @banner.destroy
    head :no_content
  end

  private

  def banner_params
    params.require(:banner).permit(:announcement, :button_text, :button_link)
  end
end