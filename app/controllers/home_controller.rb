class HomeController < ApplicationController
  def index
    render({ :template => "home_templates/index" })
  end

  def new_user
    render({ :template => "home_templates/new_user"})
  end

  def rules
    render({ :template => "home_templates/rules"})
  end
end
