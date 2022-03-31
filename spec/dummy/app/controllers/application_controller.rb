class ApplicationController < ActionController::API

  def render_error(err)
    render json: err, status: 400
  end

  def render_ok(data = {})
    render json: data, status: 201
  end
end
