require "rails/all"

RSpec.describe NamedController, type: :controller do
  let(:admin) { User.create(email: "admin@admin.admin", admin: true) }
  let(:non_admin) { User.create(email: "nonadmin@user.user", admin: false)}

  describe 'single named' do 
    after(:each) { Post.delete_all }

    it 'creates a simple post' do 
      post :create_post, params: { post: { title: "A title" }}

      expect(response.status).to be(201)
    end

    it 'fails on an activerecord error' do
      post :create_post, params: { post: { body: "Body Text" }}
      expect(response.status).to be(400)
    end

    it "check the validation block fails" do
      post :create_post, params: { post: { title: "Number 1!" }}
      expect(response.status).to be(400)
    end

    it "checks a stateful validation" do
      params = {
        current_user_id: admin.id,
        post: { title: "Number 1!" }
      }
      post :create_post, params: params
      expect(response.status).to be(201)
    end

    it "checks a stateful validation" do
      params = {
        current_user_id: non_admin.id,
        post: { title: "Number 1!" }
      }
      post :create_post, params: params
      expect(response.status).to be(400)
    end
  end

  describe 'iterating named' do 
    after(:each) { Post.delete_all }

    it 'creates two posts' do
      params = {
        posts: [
          { title: "A title"},
          { title: "A second title"}
        ]
      }

      post :create_posts, params: params

      expect(response.status).to be(201)
      expect(Post.count).to be(2)
    end

    it 'fails if one is incorrect' do
      params = {
        posts: [
          { title: "A title"},
          { title: "A second title 1"}
        ]
      }

      post :create_posts, params: params

      expect(response.status).to be(400)
      expect(Post.count).to be(0)
      body = JSON.parse response.parsed_body

      expect(body.first).to be_empty
      expect(body.last).to have_key("title")
    end
  end
end