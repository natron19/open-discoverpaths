class PathSetsController < ApplicationController
  before_action :load_path_set, only: [:show, :regenerate, :compare, :download]
  rate_limit to: 10, within: 1.minute, only: [:create, :regenerate],
             by: -> { current_user&.id || request.remote_ip },
             with: -> { render partial: "shared/ai_error", locals: { error_type: :error } }

  def create
    foundation = current_user.personal_foundation
    return render file: Rails.public_path.join("404.html"), status: :not_found unless foundation

    raw = GeminiService.generate(
      template:  "discoverpaths_pathset_v1",
      variables: foundation_variables(foundation)
    )

    @path_set = build_path_set(foundation, raw)
    redirect_to path_set_path(@path_set)

  rescue GeminiService::BudgetExceededError
    @error_type = :budget_exceeded
    render "path_sets/ai_error"
  rescue GeminiService::GatekeeperError
    @error_type = :gatekeeper_blocked
    render "path_sets/ai_error"
  rescue GeminiService::TimeoutError
    @error_type = :timeout
    render "path_sets/ai_error"
  rescue GeminiService::GeminiError
    @error_type = :error
    render "path_sets/ai_error"
  end

  def show
    @life_paths = @path_set.life_paths.order(:position)
  end

  def regenerate
    foundation = current_user.personal_foundation
    return render file: Rails.public_path.join("404.html"), status: :not_found unless foundation

    raw = GeminiService.generate(
      template:  "discoverpaths_pathset_v1",
      variables: foundation_variables(foundation)
    )

    ActiveRecord::Base.transaction do
      @path_set.life_paths.destroy_all
      parse_paths(raw).each_with_index do |attrs, i|
        @path_set.life_paths.create!(life_path_attrs(attrs, i))
      end
      @path_set.update!(gemini_raw: raw, generated_at: Time.current)
    end

    redirect_to path_set_path(@path_set), notice: "Path set regenerated."

  rescue GeminiService::BudgetExceededError
    @error_type = :budget_exceeded
    render "path_sets/ai_error"
  rescue GeminiService::GatekeeperError
    @error_type = :gatekeeper_blocked
    render "path_sets/ai_error"
  rescue GeminiService::TimeoutError
    @error_type = :timeout
    render "path_sets/ai_error"
  rescue GeminiService::GeminiError
    @error_type = :error
    render "path_sets/ai_error"
  end

  def download
    life_paths = @path_set.life_paths.order(:position)
    markdown   = build_markdown(@path_set, life_paths)
    filename   = "discoverpaths-#{@path_set.generated_at.strftime('%Y-%m-%d')}.md"
    send_data markdown, filename: filename, type: "text/markdown", disposition: "attachment"
  end

  def compare
    if params[:path_a].blank? || params[:path_b].blank?
      return redirect_to path_set_path(@path_set)
    end

    @path_a = @path_set.life_paths.find_by(id: params[:path_a])
    @path_b = @path_set.life_paths.find_by(id: params[:path_b])

    return render file: Rails.public_path.join("404.html"), status: :not_found unless @path_a && @path_b
  end

  private

  def build_markdown(path_set, life_paths)
    lines = []
    lines << "# Path Set"
    lines << ""
    lines << "Generated #{path_set.generated_at.strftime('%B %-d, %Y')} · " \
             "Based on your foundation as of #{path_set.personal_foundation.updated_at.strftime('%b %-d, %Y')}"
    lines << ""

    life_paths.each do |lp|
      lines << "---"
      lines << ""

      header = "## #{lp.name}"
      header += " *(Exit Path)*"    if lp.is_exit_path?
      header += " *(Long-Shot Path)*" if lp.is_long_shot?
      lines << header
      lines << ""
      lines << lp.positioning
      lines << ""

      lines << "### Milestones"
      lp.milestones.split("\n").each { |m| lines << "- #{m}" }
      lines << ""

      lines << "### Demands"
      lp.demands.split("\n").each_with_index { |d, i| lines << "#{i + 1}. #{d}" }
      lines << ""

      lines << "### Trade-offs"
      lp.trade_offs.split("\n").each_with_index { |t, i| lines << "#{i + 1}. #{t}" }
      lines << ""

      lines << "### Real People"
      lp.real_people.split("\n").each { |p| lines << "- #{p}" }
      lines << ""
    end

    lines << "---"
    lines << ""
    lines << "*These paths are starting points for your own thinking, generated from what you wrote in your foundation.*"
    lines << ""

    lines.join("\n")
  end

  def load_path_set
    @path_set = current_user.path_sets
                            .includes(:life_paths, :personal_foundation)
                            .find_by(id: params[:id])
    render file: Rails.public_path.join("404.html"), status: :not_found unless @path_set
  end

  def foundation_variables(foundation)
    {
      values:             foundation.values,
      strengths:          foundation.strengths,
      constraints:        foundation.constraints,
      resources:          foundation.resources,
      current_trajectory: foundation.current_trajectory
    }
  end

  def build_path_set(foundation, raw)
    ActiveRecord::Base.transaction do
      path_set = current_user.path_sets.create!(
        personal_foundation: foundation,
        gemini_raw:          raw,
        generated_at:        Time.current
      )
      parse_paths(raw).each_with_index do |attrs, i|
        path_set.life_paths.create!(life_path_attrs(attrs, i))
      end
      path_set
    end
  end

  def parse_paths(raw)
    # Strip markdown code fences Gemini sometimes adds despite instructions
    cleaned = raw.gsub(/\A```(?:json)?\s*/i, "").gsub(/\s*```\z/, "").strip
    data    = JSON.parse(cleaned)
    paths   = data["paths"]
    raise GeminiService::GeminiError, "Invalid response structure" unless paths.is_a?(Array)

    enforce_single_flag!(paths, "is_exit_path")
    enforce_single_flag!(paths, "is_long_shot")
    paths
  rescue JSON::ParserError => e
    raise GeminiService::GeminiError, "JSON parse failed: #{e.message}"
  end

  def enforce_single_flag!(paths, flag)
    flagged = paths.select { |p| p[flag] }
    return if flagged.length <= 1
    Rails.logger.warn "DiscoverPaths: #{flagged.length} paths with #{flag}=true; keeping first."
    flagged[1..].each { |p| p[flag] = false }
  end

  def life_path_attrs(attrs, position)
    {
      name:         attrs["name"],
      positioning:  attrs["positioning"],
      milestones:   [
        "Year 1: #{attrs.dig('milestones', 'year_1')}",
        "Year 3: #{attrs.dig('milestones', 'year_3')}",
        "Year 10: #{attrs.dig('milestones', 'year_10')}"
      ].join("\n"),
      demands:      Array(attrs["demands"]).join("\n"),
      trade_offs:   Array(attrs["trade_offs"]).join("\n"),
      real_people:  Array(attrs["real_people"]).join("\n"),
      is_exit_path: attrs["is_exit_path"] || false,
      is_long_shot: attrs["is_long_shot"] || false,
      position:     position
    }
  end
end
