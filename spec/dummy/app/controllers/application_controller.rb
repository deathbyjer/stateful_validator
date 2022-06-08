class ApplicationController < ActionController::API
  def current_user
    @current_user ||= User.find_by(id: params[:current_user_id])
  end

  def render_error(err)
    render json: err, status: 400
  end

  def render_ok(data = {})
    render json: data, status: 201
  end
end
