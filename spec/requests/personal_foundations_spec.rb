require "rails_helper"

RSpec.describe "PersonalFoundations", type: :request do
  let(:user) { create(:user) }

  let(:valid_params) do
    {
      personal_foundation: {
        values:             "Autonomy: I want to control my own time. Craft: I care about doing things well. Honesty: I do not sell things I do not believe in.",
        strengths:          "Writing: published newsletter with 4,000 readers for three years. Teaching: workshops since 2022 with strong feedback.",
        constraints:        "Financial: need at least $90k per year. Geographic: anchored to one city for four years.",
        resources:          "Skills: writing, facilitation. Network: 60 contacts in my field. Capital: 14 months runway.",
        current_trajectory: "If I keep doing what I am doing I will get one promotion and stay put indefinitely."
      }
    }
  end

  describe "unauthenticated access" do
    it "redirects GET /personal_foundation/new to sign in" do
      get new_personal_foundation_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects GET /personal_foundation to sign in" do
      get personal_foundation_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects GET /personal_foundation/edit to sign in" do
      get edit_personal_foundation_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects PATCH /personal_foundation to sign in" do
      patch personal_foundation_path, params: valid_params
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /personal_foundation/new" do
    before { sign_in_as(user) }

    it "returns 200 when no foundation exists" do
      get new_personal_foundation_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects to show when a foundation already exists" do
      create(:personal_foundation, user: user)
      get new_personal_foundation_path
      expect(response).to redirect_to(personal_foundation_path)
    end
  end

  describe "POST /personal_foundation" do
    before { sign_in_as(user) }

    it "creates a foundation scoped to the current user" do
      expect { post personal_foundation_path, params: valid_params }
        .to change(PersonalFoundation, :count).by(1)
      expect(PersonalFoundation.last.user).to eq(user)
    end

    it "redirects to the dashboard on success" do
      post personal_foundation_path, params: valid_params
      expect(response).to redirect_to(dashboard_path)
    end

    it "re-renders the form when data is invalid" do
      post personal_foundation_path, params: { personal_foundation: { values: "short" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a foundation for another user" do
      post personal_foundation_path, params: valid_params
      other_user = create(:user)
      expect(other_user.personal_foundation).to be_nil
    end
  end

  describe "GET /personal_foundation" do
    before { sign_in_as(user) }

    it "returns 200 for the foundation owner" do
      create(:personal_foundation, user: user)
      get personal_foundation_path
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 when no foundation exists" do
      get personal_foundation_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /personal_foundation/edit" do
    before { sign_in_as(user) }

    it "returns 200 when a foundation exists" do
      create(:personal_foundation, user: user)
      get edit_personal_foundation_path
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 when no foundation exists" do
      get edit_personal_foundation_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /personal_foundation" do
    before { sign_in_as(user) }

    it "updates the current user's foundation" do
      foundation = create(:personal_foundation, user: user)
      patch personal_foundation_path, params: {
        personal_foundation: { values: "Updated values that are long enough to satisfy the minimum length validation." }
      }
      expect(foundation.reload.values).to start_with("Updated values")
    end

    it "redirects to the dashboard on success" do
      create(:personal_foundation, user: user)
      patch personal_foundation_path, params: valid_params
      expect(response).to redirect_to(dashboard_path)
    end

    it "re-renders edit with invalid data" do
      create(:personal_foundation, user: user)
      patch personal_foundation_path, params: { personal_foundation: { values: "x" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
