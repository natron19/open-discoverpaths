class LifePathsController < ApplicationController
  before_action :load_life_path

  def edit
  end

  def update
    if @life_path.update(life_path_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "life_path_#{@life_path.id}",
            partial: "path_sets/path_card",
            locals: { life_path: @life_path }
          )
        end
        format.html { redirect_to path_set_path(@life_path.path_set) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "life_path_#{@life_path.id}",
            partial: "life_paths/edit_form",
            locals: { life_path: @life_path }
          )
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_life_path
    path_set_ids = current_user.path_sets.pluck(:id)
    @life_path   = LifePath.find_by(id: params[:id], path_set_id: path_set_ids)
    render file: Rails.public_path.join("404.html"), status: :not_found unless @life_path
  end

  def life_path_params
    params.require(:life_path)
          .permit(:name, :positioning, :milestones, :demands, :trade_offs, :real_people)
  end
end
