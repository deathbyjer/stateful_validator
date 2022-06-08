Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post 'user' => 'user#create'
  post 'user/validations' => 'user#validations'

  post 'named/user' => 'named#create_user'
  post 'named/post' => 'named#create_post'

  post 'named/posts' => 'named#create_posts'
end
