class PersonalFoundationsController < ApplicationController
  before_action :load_foundation, only: [:show, :edit, :update]

  def new
    if current_user.personal_foundation
      redirect_to personal_foundation_path and return
    end
    @foundation = current_user.build_personal_foundation
  end

  def create
    @foundation = current_user.build_personal_foundation(foundation_params)
    if @foundation.save
      redirect_to dashboard_path, notice: "Foundation saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit; end

  def update
    if @foundation.update(foundation_params)
      redirect_to dashboard_path, notice: "Foundation updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_foundation
    @foundation = current_user.personal_foundation
    render file: Rails.public_path.join("404.html"), status: :not_found unless @foundation
  end

  def foundation_params
    params.require(:personal_foundation)
          .permit(:values, :strengths, :constraints, :resources, :current_trajectory)
  end
end
