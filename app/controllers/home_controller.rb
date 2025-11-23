class HomeController < ApplicationController
  def index
    render({ :template => "home_templates/index" })
  end

  def new_user
    render({ :template => "home_templates/new_user"})
  end
end
