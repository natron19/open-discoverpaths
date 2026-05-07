require "rails_helper"

RSpec.describe "PathSets", type: :request do
  let(:user)       { create(:user) }
  let(:foundation) { create(:personal_foundation, user: user) }

  before { foundation }

  describe "unauthenticated access" do
    it "redirects POST /path_sets to sign in" do
      post path_sets_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects GET /path_sets/:id to sign in" do
      get path_set_path(SecureRandom.uuid)
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "POST /path_sets" do
    before do
      sign_in_as(user)
      allow(GeminiService).to receive(:generate).and_return(SAMPLE_PATHSET_JSON)
    end

    it "creates a PathSet with 5 LifePath children" do
      expect { post path_sets_path }
        .to change(PathSet, :count).by(1)
        .and change(LifePath, :count).by(5)
    end

    it "scopes the PathSet to the current user" do
      post path_sets_path
      expect(PathSet.last.user).to eq(user)
    end

    it "calls GeminiService with the correct template" do
      post path_sets_path
      expect(GeminiService).to have_received(:generate)
        .with(hash_including(template: "discoverpaths_pathset_v1"))
    end

    it "redirects to the path set show page" do
      post path_sets_path
      expect(response).to redirect_to(path_set_path(PathSet.last))
    end

    it "flags exactly one exit path and one long-shot" do
      post path_sets_path
      paths = PathSet.last.life_paths
      expect(paths.where(is_exit_path: true).count).to eq(1)
      expect(paths.where(is_long_shot: true).count).to eq(1)
    end

    it "renders the error page on GeminiError" do
      allow(GeminiService).to receive(:generate).and_raise(GeminiService::GeminiError, "test error")
      post path_sets_path
      expect(response.body).to include("Something went wrong")
    end

    it "renders the error page on TimeoutError" do
      allow(GeminiService).to receive(:generate).and_raise(GeminiService::TimeoutError, "timeout")
      post path_sets_path
      expect(response.body).to include("took too long")
    end

    it "renders the error page on BudgetExceededError" do
      allow(GeminiService).to receive(:generate).and_raise(GeminiService::BudgetExceededError, "over limit")
      post path_sets_path
      expect(response.body).to include("daily AI request limit")
    end

    it "returns 404 when the user has no foundation" do
      user_without_foundation = create(:user)
      sign_in_as(user_without_foundation)
      post path_sets_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /path_sets/:id" do
    let(:path_set) { create(:path_set, :with_life_paths, user: user, personal_foundation: foundation) }

    before { sign_in_as(user) }

    it "returns 200 for the owner" do
      get path_set_path(path_set)
      expect(response).to have_http_status(:ok)
    end

    it "includes the disclaimer text" do
      get path_set_path(path_set)
      expect(response.body).to include("DiscoverPaths offers paths")
    end

    it "renders all path card texture fields" do
      get path_set_path(path_set)
      lp = path_set.life_paths.first
      expect(response.body).to include(lp.name)
      expect(response.body).to include(lp.positioning)
      expect(response.body).to include("Milestones")
      expect(response.body).to include("Demands")
      expect(response.body).to include("Trade-offs")
    end

    it "returns 404 for a different user" do
      other_user = create(:user)
      sign_in_as(other_user)
      get path_set_path(path_set)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /path_sets/:id/regenerate" do
    let(:path_set) { create(:path_set, :with_life_paths, user: user, personal_foundation: foundation) }

    before do
      path_set  # force creation before any expect { } block measures the count
      sign_in_as(user)
      allow(GeminiService).to receive(:generate).and_return(SAMPLE_PATHSET_JSON)
    end

    it "destroys old life paths and creates new ones" do
      post regenerate_path_set_path(path_set)
      expect(path_set.reload.life_paths.count).to eq(5)
    end

    it "does not create a new PathSet record" do
      expect { post regenerate_path_set_path(path_set) }.not_to change(PathSet, :count)
    end

    it "redirects to the path set show page" do
      post regenerate_path_set_path(path_set)
      expect(response).to redirect_to(path_set_path(path_set))
    end
  end

  describe "GET /path_sets/:id/compare" do
    let(:path_set) { create(:path_set, :with_life_paths, user: user, personal_foundation: foundation) }

    before { sign_in_as(user) }

    it "returns 200 with valid path_a and path_b" do
      paths = path_set.life_paths.first(2)
      get compare_path_set_path(path_set, path_a: paths[0].id, path_b: paths[1].id)
      expect(response).to have_http_status(:ok)
    end

    it "renders both path names in the response" do
      paths = path_set.life_paths.first(2)
      get compare_path_set_path(path_set, path_a: paths[0].id, path_b: paths[1].id)
      expect(response.body).to include(paths[0].name)
      expect(response.body).to include(paths[1].name)
    end

    it "redirects to show when params are missing" do
      get compare_path_set_path(path_set)
      expect(response).to redirect_to(path_set_path(path_set))
    end

    it "returns 404 when path_a does not belong to this path set" do
      other_user       = create(:user)
      other_foundation = create(:personal_foundation, user: other_user)
      other_set        = create(:path_set, :with_life_paths, user: other_user, personal_foundation: other_foundation)
      path_b           = path_set.life_paths.first
      path_a           = other_set.life_paths.first
      get compare_path_set_path(path_set, path_a: path_a.id, path_b: path_b.id)
      expect(response).to have_http_status(:not_found)
    end
  end
end
