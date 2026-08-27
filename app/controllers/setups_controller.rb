class SetupsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_configured

  def show
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Your account is ready."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.expect(user: [ :email_address, :password, :password_confirmation ])
    end

    def redirect_if_configured
      redirect_to(authenticated? ? root_path : new_session_path) if User.exists?
    end
end
