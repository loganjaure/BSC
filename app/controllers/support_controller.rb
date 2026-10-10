# frozen_string_literal: true

# AC-23.1: static help page explaining how to use the app without the dev team
class SupportController < ApplicationController
  # Public so signed-out visitors and members with an unfinished profile can still read it
  skip_before_action :require_login
  skip_before_action :ensure_profile_complete

  def show
  end
end
