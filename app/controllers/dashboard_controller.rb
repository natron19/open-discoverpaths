class DashboardController < ApplicationController
  def show
    @foundation = current_user.personal_foundation
    @path_sets  = current_user.path_sets.order(generated_at: :desc).limit(10)
  end
end
