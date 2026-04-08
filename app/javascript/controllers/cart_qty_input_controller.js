import { Controller } from "@hotwired/stimulus"

// Submits the surrounding form when the quantity changes (blur or Enter), clamped to 0..max (0 removes line).
export default class extends Controller {
  static values = { max: Number }

  connect() {
    this.syncLastCommitted()
  }

  syncLastCommitted() {
    const v = parseInt(this.element.value, 10)
    this.lastCommitted = Number.isNaN(v) ? 0 : v
  }

  submitOnEnter(event) {
    if (event.key !== "Enter") return
    event.preventDefault()
    this.commit()
  }

  commitOnBlur() {
    this.commit()
  }

  commit() {
    const raw = this.element.value.trim()
    let v = parseInt(raw, 10)
    if (Number.isNaN(v)) {
      this.element.value = this.lastCommitted
      return
    }
    v = Math.max(0, Math.min(this.maxValue, v))
    this.element.value = v
    if (v === this.lastCommitted) return
    this.lastCommitted = v
    this.element.form.requestSubmit()
  }
}
