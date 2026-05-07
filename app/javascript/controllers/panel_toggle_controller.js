import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button"]
  static values  = { active: { type: Number, default: 0 } }

  connect() {
    this.showPanel(this.activeValue)
  }

  show(event) {
    const index = this.buttonTargets.indexOf(event.currentTarget)
    this.showPanel(index)
  }

  showPanel(activeIndex) {
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("d-none", i !== activeIndex)
    })
    this.buttonTargets.forEach((btn, i) => {
      btn.classList.toggle("active", i === activeIndex)
    })
  }
}
