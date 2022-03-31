require "rails/all"

RSpec.describe UserController, type: :controller do
  describe 'simple populate' do 
    after(:each) { User.delete_all }

    it 'simple create' do 
      post :create, params: { user: { email: "foo@bar.com" }}
    end

    it 'fails without an email' do
      post :create, params: {}
      expect(response.status).to be(400)
    end
  end

  describe 'validate + populate' do
    after(:each) { User.delete_all }

    it "triggers validations" do
      post :validations, params: {}
      expect(response.status).to be(400)

      body = JSON.parse response.parsed_body
      expect(body['email']).to eq("required")
    end

    it "hits the first failed validation" do
      post :validations, params: { user: { email: "hi" }}
      expect(response.status).to be(400)
      body = JSON.parse response.parsed_body
      expect(body['email']).to eq("invalid")
    end

    it "generates when validations are passed" do
      post :validations, params: { user: { email: "foo@bar.com"}}
      expect(response.status).to be(201)
    end
  end
end