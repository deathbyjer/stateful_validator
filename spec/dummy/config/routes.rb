Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post 'user' => 'user#create'
  post 'user/special' => 'user#special_create'
  post 'user/validations' => 'user#validations'

  post 'named/user' => 'named#create_user'
  post 'named/post' => 'named#create_post'
  post 'named/global_post' => 'named#create_global_post'

  post 'named/posts' => 'named#create_posts'
  post 'named/posts_list' => 'named#check_post_list'
end
