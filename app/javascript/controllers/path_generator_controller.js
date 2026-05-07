import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["idle", "loading"]

  start() {
    this.idleTarget.classList.add("d-none")
    this.loadingTarget.classList.remove("d-none")
  }
}
