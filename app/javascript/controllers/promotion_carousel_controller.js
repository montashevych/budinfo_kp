import { Controller } from "@hotwired/stimulus"

// Phase 4: values only (wired from the home partial). Phase 5: autoplay, prev/next, a11y.
export default class extends Controller {
  static values = {
    count: { type: Number, default: 0 },
    urls: { type: Array, default: [] }
  }
}
