class LocalesController < ApplicationController
  allow_unauthenticated_access

  def update
    redirect_back fallback_location: root_path, status: :see_other
  end
end
