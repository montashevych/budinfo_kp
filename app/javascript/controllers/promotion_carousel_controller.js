import { Controller } from "@hotwired/stimulus"

const DEFAULT_INTERVAL_MS = 10_000

export default class extends Controller {
  static targets = ["slide", "live", "prev", "next"]
  static values = {
    intervalMs: { type: Number, default: DEFAULT_INTERVAL_MS }
  }

  connect() {
    this.currentIndex = 0
    this.hoverPaused = false
    this.focusInside = false
    this.timer = null

    this.boundPauseHover = () => this.setHoverPaused(true)
    this.boundResumeHover = () => this.setHoverPaused(false)
    this.boundFocusIn = () => this.setFocusInside(true)
    this.boundFocusOut = () => this.handleFocusOut()

    this.element.addEventListener("mouseenter", this.boundPauseHover)
    this.element.addEventListener("mouseleave", this.boundResumeHover)
    this.element.addEventListener("focusin", this.boundFocusIn)
    this.element.addEventListener("focusout", this.boundFocusOut)

    const n = this.slideTargets.length
    if (n < 2) {
      this.slideTargets.forEach((el) => {
        el.classList.toggle("hidden", false)
        el.setAttribute("aria-hidden", "false")
      })
      this.updateLive()
      return
    }

    this.show(0)
    this.element.setAttribute("tabindex", "0")
    this.boundKeydown = (e) => this.onKeydown(e)
    this.element.addEventListener("keydown", this.boundKeydown)
    this.startAutoplay()
  }

  restartAutoplayAfterManualNav() {
    if (this.slideTargets.length < 2) return
    if (this.hoverPaused || this.focusInside) return
    this.startAutoplay()
  }

  disconnect() {
    this.stopAutoplay()
    this.element.removeEventListener("mouseenter", this.boundPauseHover)
    this.element.removeEventListener("mouseleave", this.boundResumeHover)
    this.element.removeEventListener("focusin", this.boundFocusIn)
    this.element.removeEventListener("focusout", this.boundFocusOut)
    if (this.boundKeydown) {
      this.element.removeEventListener("keydown", this.boundKeydown)
    }
    this.element.removeAttribute("tabindex")
  }

  prev(event) {
    event?.preventDefault()
    const n = this.slideTargets.length
    if (n < 2) return
    this.show((this.currentIndex - 1 + n) % n)
    this.restartAutoplayAfterManualNav()
  }

  /** Autoplay tick (no event) — do not reset interval; setInterval already drives cadence. */
  advance() {
    const n = this.slideTargets.length
    if (n < 2) return
    this.show((this.currentIndex + 1) % n)
  }

  next(event) {
    event?.preventDefault()
    const n = this.slideTargets.length
    if (n < 2) return
    this.show((this.currentIndex + 1) % n)
    if (event) this.restartAutoplayAfterManualNav()
  }

  show(index) {
    this.currentIndex = index
    this.slideTargets.forEach((el, idx) => {
      const hide = idx !== index
      el.classList.toggle("hidden", hide)
      el.setAttribute("aria-hidden", hide ? "true" : "false")
    })
    this.updateLive()
  }

  updateLive() {
    if (!this.hasLiveTarget) return
    const slide = this.slideTargets[this.currentIndex]
    const title = slide?.dataset.carouselTitle || ""
    const n = this.slideTargets.length
    if (n < 2) {
      this.liveTarget.textContent = title
      return
    }
    this.liveTarget.textContent = `${this.currentIndex + 1} / ${n}: ${title}`
  }

  onKeydown(event) {
    if (this.slideTargets.length < 2) return
    if (event.key === "ArrowLeft") {
      event.preventDefault()
      this.prev(event)
    } else if (event.key === "ArrowRight") {
      event.preventDefault()
      this.next(event)
    }
  }

  setHoverPaused(value) {
    this.hoverPaused = value
    this.syncAutoplay()
  }

  setFocusInside(value) {
    this.focusInside = value
    this.syncAutoplay()
  }

  handleFocusOut() {
    window.requestAnimationFrame(() => {
      if (!this.element.contains(document.activeElement)) {
        this.setFocusInside(false)
      }
    })
  }

  syncAutoplay() {
    if (this.slideTargets.length < 2) return
    if (this.hoverPaused || this.focusInside) {
      this.stopAutoplay()
    } else {
      this.startAutoplay()
    }
  }

  startAutoplay() {
    this.stopAutoplay()
    const ms = Number.isFinite(this.intervalMsValue) ? this.intervalMsValue : DEFAULT_INTERVAL_MS
    this.timer = window.setInterval(() => this.advance(), ms)
  }

  stopAutoplay() {
    if (this.timer) {
      window.clearInterval(this.timer)
      this.timer = null
    }
  }

}
