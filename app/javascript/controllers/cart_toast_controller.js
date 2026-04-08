import { Controller } from "@hotwired/stimulus"

// Fades out then removes streamed cart toasts.
export default class extends Controller {
  connect() {
    this.showTimeoutId = window.setTimeout(() => this.fadeOutAndRemove(), 2800)
  }

  fadeOutAndRemove() {
    this.element.style.transition = "opacity 0.35s ease, transform 0.35s ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-0.25rem)"
    this.removeTimeoutId = window.setTimeout(() => this.element.remove(), 380)
  }

  disconnect() {
    window.clearTimeout(this.showTimeoutId)
    window.clearTimeout(this.removeTimeoutId)
  }
}
