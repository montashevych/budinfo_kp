import { Controller } from "@hotwired/stimulus"

// Removes streamed toast after a short delay.
export default class extends Controller {
  connect() {
    this.timeoutId = window.setTimeout(() => {
      this.element.remove()
    }, 3200)
  }

  disconnect() {
    window.clearTimeout(this.timeoutId)
  }
}
