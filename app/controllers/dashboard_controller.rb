class DashboardController < ApplicationController
  # Old dashboard replaced by the home page (points + events live there now)
  def show
    flash.keep
    redirect_to root_path
  end
end
