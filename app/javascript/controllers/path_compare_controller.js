import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["path_a_select", "path_b_select", "compare_link"]
  static values  = { baseUrl: String }

  connect() {
    this.update()
  }

  update() {
    const a     = this.path_a_selectTarget.value
    const b     = this.path_b_selectTarget.value
    const valid = a && b && a !== b

    if (valid) {
      this.compare_linkTarget.removeAttribute("disabled")
      this.compare_linkTarget.value = "Compare"
    } else {
      this.compare_linkTarget.setAttribute("disabled", "disabled")
    }
  }
}
