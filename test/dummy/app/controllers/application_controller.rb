# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def create
    user_path(1)
    user_url(1)
    users_path
    archive_users_path
    invalid_path
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
