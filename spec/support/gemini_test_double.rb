SAMPLE_PATHSET_JSON = JSON.generate({
  paths: [
    { name: "Independent Consultant", positioning: "Run a one-person design consulting practice.",
      milestones: { year_1: "First two clients.", year_3: "$100k revenue.", year_10: "Waiting list." },
      demands: ["Business development", "Income variability tolerance", "Self-discipline"],
      trade_offs: ["No benefits", "Slower career signal", "Isolation"],
      real_people: ["A former in-house designer who left to freelance.", "A studio owner with 15 years agency background.", "A writer-designer who turned a newsletter into consulting."],
      is_exit_path: false, is_long_shot: false },
    { name: "Newsletter and Courses", positioning: "Build an audience-driven education business.",
      milestones: { year_1: "First paid course.", year_3: "200 students.", year_10: "Sustainable course library." },
      demands: ["Consistent publishing", "Product discipline", "Patience"],
      trade_offs: ["Unpredictable income", "Public exposure", "Long feedback loops"],
      real_people: ["A designer who left to teach online.", "A writer who built paid workshops.", "A developer who productized a course."],
      is_exit_path: false, is_long_shot: false },
    { name: "Design Leadership", positioning: "Move into a Head of Design role at a mid-stage startup.",
      milestones: { year_1: "Head of Design title.", year_3: "Team of five.", year_10: "VP or CPO." },
      demands: ["Political navigation", "People management", "Equity risk tolerance"],
      trade_offs: ["Less craft time", "Company outcome risk", "Slower if company fails"],
      real_people: ["A senior IC who moved into management.", "A consultant who joined as design lead.", "A head of design who made VP post-acquisition."],
      is_exit_path: false, is_long_shot: false },
    { name: "Return to Stable Employment", positioning: "Take a senior IC role at a larger company.",
      milestones: { year_1: "Role secured.", year_3: "One promotion.", year_10: "Staff or principal." },
      demands: ["Accepting slower pace", "Corporate navigation", "Side project discipline"],
      trade_offs: ["Less autonomy", "Slower wealth building", "Newsletter stays a hobby"],
      real_people: ["A freelancer who returned to full-time.", "A startup veteran who joined big co.", "A consultant who took in-house for benefits."],
      is_exit_path: true, is_long_shot: false },
    { name: "Build a SaaS Product", positioning: "Turn a workflow problem into a small SaaS for design teams.",
      milestones: { year_1: "10 paying customers.", year_3: "$5k MRR.", year_10: "Acquired or sustainable." },
      demands: ["Technical learning or co-founder", "Long unpaid runway", "Product obsession"],
      trade_offs: ["High failure rate", "Years before payoff", "Financial risk"],
      real_people: ["A designer who built a tool for their old team.", "A solo founder with 8 years runway.", "A consultant who productized a service."],
      is_exit_path: false, is_long_shot: true }
  ]
}).freeze

module GeminiTestDouble
  def gemini_returns(text = "Stubbed AI response.")
    allow(GeminiService).to receive(:generate).and_return(text)
  end

  def gemini_raises(error_class, message = "Stubbed error")
    allow(GeminiService).to receive(:generate).and_raise(error_class, message)
  end
end

RSpec.configure do |config|
  config.include GeminiTestDouble
end
