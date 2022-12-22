require "rails/all"

RSpec.describe UserController, type: :controller do
  before(:all) { User.delete_all }
  
  describe 'simple populate' do 
    after(:each) { User.delete_all }

    it 'specific create' do 
      email = "foo2@bar5.com"
      post :special_create, params: { user: { email: email }}
      expect(User.count).to eq(1)
      expect(User.first.email).not_to eq(email)
    end
  end

  describe 'validate + populate' do

  end
end