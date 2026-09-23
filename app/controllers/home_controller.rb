class HomeController < ApplicationController
  skip_before_action :require_login, only: [ :index ]

  def index
    redirect_to dashboard_path if logged_in?
  end
end
