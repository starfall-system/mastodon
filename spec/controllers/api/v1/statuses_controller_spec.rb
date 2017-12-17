require 'rails_helper'

RSpec.describe Api::V1::StatusesController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:app)   { Fabricate(:application, name: 'Test app', website: 'http://testapp.com') }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, application: app, scopes: 'write') }

  context 'with an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'GET #show' do
      let(:status) { Fabricate(:status, account: user.account) }

      it 'returns http success' do
        get :show, params: { id: status.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'GET #context' do
      let(:status) { Fabricate(:status, account: user.account) }

      before do
        Fabricate(:status, account: user.account, thread: status)
      end

      it 'returns http success' do
        get :context, params: { id: status.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'POST #create' do
      context 'with local_only unspecified and no eyeball' do
        before do
          post :create, params: { status: 'Hello world' }
        end

        let(:status_response) { JSON.parse(response.body) }

        it 'returns http success' do
          expect(response).to have_http_status(:success)
        end

        it 'creates a non-local-only status' do
          expect(status_response["local_only"]).to be false
        end
      end

      context 'with local_only unspecified and an eyeball' do
        before do
          post :create, params: { status: "Hello world #{Status.new.local_only_emoji}" }
        end

        let(:status_response) { JSON.parse(response.body) }

        it 'returns http success' do
          expect(response).to have_http_status(:success)
        end

        it 'creates a local-only status' do
          expect(status_response["local_only"]).to be true
        end
      end


      context 'with local_only set to true' do
        before do
          post :create, params: { status: 'Hello world', local_only: true }
        end

        let(:status_response) { JSON.parse(response.body) }

        it 'returns http success' do
          expect(response).to have_http_status(:success)
        end

        it 'creates a local-only status' do
          expect(status_response["local_only"]).to be true
        end
      end

      context 'with local_only set to false' do
        before do
          post :create, params: { status: 'Hello world', local_only: false }
        end

        let(:status_response) { JSON.parse(response.body) }

        it 'returns http success' do
          expect(response).to have_http_status(:success)
        end

        it 'creates a non-local-only status' do
          expect(status_response["local_only"]).to be false
        end
      end

    end

    describe 'DELETE #destroy' do
      let(:status) { Fabricate(:status, account: user.account) }

      before do
        post :destroy, params: { id: status.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'removes the status' do
        expect(Status.find_by(id: status.id)).to be nil
      end
    end

    describe 'the "local_only" property' do
      context 'for a local-only status' do
        let(:status) { Fabricate(:status, account: user.account, local_only: true) }

        before do
          get :show, params: { id: status.id }
        end

        let(:status_response) { JSON.parse(response.body) }

        it 'is true' do
          expect(status_response["local_only"]).to be true
        end
      end

      context 'for a non-local-only status' do
        let(:status) { Fabricate(:status, account: user.account, local_only: false) }

        before do
          get :show, params: { id: status.id }
        end

        let(:status_response) { JSON.parse(response.body) }

        it 'is false' do
          expect(status_response["local_only"]).to be false
        end
      end
    end
  end

  context 'without an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { nil }
    end

    context 'with a private status' do
      let(:status) { Fabricate(:status, account: user.account, visibility: :private) }

      describe 'GET #show' do
        it 'returns http unautharized' do
          get :show, params: { id: status.id }
          expect(response).to have_http_status(:missing)
        end
      end

      describe 'GET #context' do
        before do
          Fabricate(:status, account: user.account, thread: status)
        end

        it 'returns http unautharized' do
          get :context, params: { id: status.id }
          expect(response).to have_http_status(:missing)
        end
      end

      describe 'GET #card' do
        it 'returns http unautharized' do
          get :card, params: { id: status.id }
          expect(response).to have_http_status(:missing)
        end
      end
    end

    context 'with a public status' do
      let(:status) { Fabricate(:status, account: user.account, visibility: :public) }

      describe 'GET #show' do
        it 'returns http success' do
          get :show, params: { id: status.id }
          expect(response).to have_http_status(:success)
        end
      end

      describe 'GET #context' do
        before do
          Fabricate(:status, account: user.account, thread: status)
        end

        it 'returns http success' do
          get :context, params: { id: status.id }
          expect(response).to have_http_status(:success)
        end
      end

      describe 'GET #card' do
        it 'returns http success' do
          get :card, params: { id: status.id }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'with a local-only status' do
      let(:status) { Fabricate(:status, account: user.account, visibility: :public, local_only: true) }

      describe 'GET #show' do
        it 'returns http unautharized' do
          get :show, params: { id: status.id }
          expect(response).to have_http_status(:missing)
        end
      end

      describe 'GET #context' do
        before do
          Fabricate(:status, account: user.account, thread: status)
        end

        it 'returns http unautharized' do
          get :context, params: { id: status.id }
          expect(response).to have_http_status(:missing)
        end
      end

      describe 'GET #card' do
        it 'returns http unautharized' do
          get :card, params: { id: status.id }
          expect(response).to have_http_status(:missing)
        end
      end
    end
  end
end
