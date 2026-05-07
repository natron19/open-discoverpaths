require "rails_helper"

RSpec.describe "LifePaths", type: :request do
  let(:user)      { create(:user) }
  let(:foundation) { create(:personal_foundation, user: user) }
  let(:path_set)  { create(:path_set, :with_life_paths, user: user, personal_foundation: foundation) }
  let(:life_path) { path_set.life_paths.first }

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "unauthenticated access" do
    it "redirects PATCH to sign in" do
      patch life_path_path(life_path), params: { life_path: { name: "New" } }
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects GET edit to sign in" do
      get edit_life_path_path(life_path)
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "PATCH /life_paths/:id" do
    before { sign_in_as(user) }

    it "updates the life path texture" do
      patch life_path_path(life_path),
            params: { life_path: { name: "Updated Name" } },
            headers: turbo_headers
      expect(life_path.reload.name).to eq("Updated Name")
    end

    it "responds with a Turbo Stream" do
      patch life_path_path(life_path),
            params: { life_path: { name: "Turbo Test" } },
            headers: turbo_headers
      expect(response.content_type).to include("turbo-stream")
    end

    it "includes the updated content in the stream" do
      patch life_path_path(life_path),
            params: { life_path: { name: "Stream Content Check" } },
            headers: turbo_headers
      expect(response.body).to include("Stream Content Check")
    end

    it "does not create an LlmRequest" do
      expect {
        patch life_path_path(life_path),
              params: { life_path: { name: "No AI" } },
              headers: turbo_headers
      }.not_to change(LlmRequest, :count)
    end

    it "returns 404 when a different signed-in user attempts the update" do
      other_user = create(:user)
      sign_in_as(other_user)
      patch life_path_path(life_path),
            params: { life_path: { name: "Hijack" } },
            headers: turbo_headers
      expect(response).to have_http_status(:not_found)
    end

    it "re-renders the edit form on invalid data" do
      patch life_path_path(life_path),
            params: { life_path: { name: "" } },
            headers: turbo_headers
      expect(response.content_type).to include("turbo-stream")
      expect(life_path.reload.name).not_to be_blank
    end
  end

  describe "GET /life_paths/:id/edit" do
    before { sign_in_as(user) }

    it "returns 200 for the owner" do
      get edit_life_path_path(life_path)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a different user" do
      other_user = create(:user)
      sign_in_as(other_user)
      get edit_life_path_path(life_path)
      expect(response).to have_http_status(:not_found)
    end
  end
end
