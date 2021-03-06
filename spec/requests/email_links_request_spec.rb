# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EmailLinks', type: :request do
  xdescribe 'GET /new' do
    it 'returns http success' do
      get '/email_links/new'
      expect(response).to have_http_status(:success)
    end
  end

  xdescribe 'GET /create' do
    it 'returns http success' do
      get '/email_links/create'
      expect(response).to have_http_status(:success)
    end
  end
end
