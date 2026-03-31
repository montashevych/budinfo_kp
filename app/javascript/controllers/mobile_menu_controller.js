import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "openButton", "closeButton"]

  open() {
    this.panelTarget.classList.remove("hidden")
    this.openButtonTarget.classList.add("hidden")
    this.closeButtonTarget.classList.remove("hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.openButtonTarget.classList.remove("hidden")
    this.closeButtonTarget.classList.add("hidden")
  }
}
