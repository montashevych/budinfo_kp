import { Controller } from "@hotwired/stimulus"

const DEFAULT_INTERVAL_MS = 10_000
const SWIPE_THRESHOLD_PX = 40
const SWIPE_DIRECTION_LOCK_PX = 8

export default class extends Controller {
  static targets = ["slide", "live", "prev", "next", "viewport"]
  static values = {
    intervalMs: { type: Number, default: DEFAULT_INTERVAL_MS }
  }

  connect() {
    this.currentIndex = 0
    this.hoverPaused = false
    this.focusInside = false
    this.timer = null
    this.swipeActive = false
    this.swipePointerId = null
    this.swipeStartX = 0
    this.swipeStartY = 0
    this.swipeLockedHorizontal = null
    this.suppressClickUntil = 0
    this.touchSwipeId = null

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
    this.setupSwipe()
  }

  restartAutoplayAfterManualNav() {
    if (this.slideTargets.length < 2) return
    if (this.hoverPaused || this.focusInside) return
    this.startAutoplay()
  }

  disconnect() {
    this.stopAutoplay()
    this.teardownSwipe()
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
    this.restartAutoplayAfterManualNav()
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

  setupSwipe() {
    if (!this.hasViewportTarget || this.slideTargets.length < 2) return

    this.boundSwipePointerDown = (e) => this.onSwipePointerDown(e)
    this.boundSwipePointerMove = (e) => this.onSwipePointerMove(e)
    this.boundSwipePointerUp = (e) => this.onSwipePointerUp(e)
    this.boundSwipeTouchStart = (e) => this.onSwipeTouchStart(e)
    this.boundSwipeTouchMove = (e) => this.onSwipeTouchMove(e)
    this.boundSwipeTouchEnd = (e) => this.onSwipeTouchEnd(e)
    this.boundSwipeClickCapture = (e) => this.onSwipeClickCapture(e)

    this.swipeMoveListenerOpts = { capture: true, passive: false }

    const vp = this.viewportTarget
    vp.addEventListener("pointerdown", this.boundSwipePointerDown, { capture: true })
    vp.addEventListener("pointermove", this.boundSwipePointerMove, this.swipeMoveListenerOpts)
    vp.addEventListener("touchstart", this.boundSwipeTouchStart, { capture: true, passive: false })
    vp.addEventListener("touchmove", this.boundSwipeTouchMove, this.swipeMoveListenerOpts)
    vp.addEventListener("touchend", this.boundSwipeTouchEnd, { capture: true, passive: false })
    vp.addEventListener("touchcancel", this.boundSwipeTouchEnd, { capture: true, passive: false })
    this.element.addEventListener("click", this.boundSwipeClickCapture, true)
  }

  teardownSwipe() {
    if (this.boundSwipePointerDown && this.hasViewportTarget) {
      const vp = this.viewportTarget
      if (this.swipePointerId != null) {
        try {
          vp.releasePointerCapture(this.swipePointerId)
        } catch (_) {
          /* ignore */
        }
      }
      vp.removeEventListener("pointerdown", this.boundSwipePointerDown, { capture: true })
      vp.removeEventListener("pointermove", this.boundSwipePointerMove, this.swipeMoveListenerOpts)
      vp.removeEventListener("touchstart", this.boundSwipeTouchStart, { capture: true, passive: false })
      vp.removeEventListener("touchmove", this.boundSwipeTouchMove, this.swipeMoveListenerOpts)
      vp.removeEventListener("touchend", this.boundSwipeTouchEnd, { capture: true, passive: false })
      vp.removeEventListener("touchcancel", this.boundSwipeTouchEnd, { capture: true, passive: false })
    }
    if (this.boundSwipeClickCapture) {
      this.element.removeEventListener("click", this.boundSwipeClickCapture, true)
    }
    if (this.boundSwipePointerUp) {
      window.removeEventListener("pointerup", this.boundSwipePointerUp, true)
      window.removeEventListener("pointercancel", this.boundSwipePointerUp, true)
    }
    this.swipeActive = false
  }

  swipeTargetIsControl(target) {
    return (
      (this.hasPrevTarget && this.prevTarget.contains(target)) ||
      (this.hasNextTarget && this.nextTarget.contains(target))
    )
  }

  onSwipePointerDown(event) {
    if (this.slideTargets.length < 2) return
    // Touch swipes use touch* listeners so we do not double-fire with Pointer Events.
    if (event.pointerType === "touch") return
    if (event.pointerType === "mouse" && event.button !== 0) return
    if (this.swipeTargetIsControl(event.target)) return

    this.swipeActive = true
    this.swipePointerId = event.pointerId
    this.swipeStartX = event.clientX
    this.swipeStartY = event.clientY
    this.swipeLockedHorizontal = null

    try {
      this.viewportTarget.setPointerCapture(event.pointerId)
    } catch (_) {
      /* ignore */
    }

    window.addEventListener("pointerup", this.boundSwipePointerUp, true)
    window.addEventListener("pointercancel", this.boundSwipePointerUp, true)
  }

  onSwipePointerMove(event) {
    if (!this.swipeActive || event.pointerId !== this.swipePointerId) return

    this.updateSwipeDirectionLock(event.clientX, event.clientY)

    if (this.swipeLockedHorizontal) {
      event.preventDefault()
    }
  }

  onSwipePointerUp(event) {
    window.removeEventListener("pointerup", this.boundSwipePointerUp, true)
    window.removeEventListener("pointercancel", this.boundSwipePointerUp, true)

    const matching = this.swipeActive && event.pointerId === this.swipePointerId
    if (!matching) return

    const dx = event.clientX - this.swipeStartX
    const dy = event.clientY - this.swipeStartY

    this.swipeActive = false
    this.swipePointerId = null

    this.finishSwipeFromDeltas(dx, dy, event)
  }

  onSwipeTouchStart(event) {
    if (this.slideTargets.length < 2) return
    if (event.touches.length !== 1) return
    if (this.swipeTargetIsControl(event.target)) return

    const t = event.touches[0]
    this.swipeActive = true
    this.touchSwipeId = t.identifier
    this.swipeStartX = t.clientX
    this.swipeStartY = t.clientY
    this.swipeLockedHorizontal = null
  }

  onSwipeTouchMove(event) {
    if (!this.swipeActive || this.touchSwipeId == null) return
    const t = Array.from(event.touches).find((touch) => touch.identifier === this.touchSwipeId)
    if (!t) return

    this.updateSwipeDirectionLock(t.clientX, t.clientY)

    if (this.swipeLockedHorizontal) {
      event.preventDefault()
    }
  }

  onSwipeTouchEnd(event) {
    if (this.touchSwipeId == null) return

    const t = Array.from(event.changedTouches).find((touch) => touch.identifier === this.touchSwipeId)

    this.swipeActive = false
    this.touchSwipeId = null

    if (!t) {
      this.swipeLockedHorizontal = null
      return
    }

    const dx = t.clientX - this.swipeStartX
    const dy = t.clientY - this.swipeStartY

    const didSwipe = this.finishSwipeFromDeltas(dx, dy, event)
    if (didSwipe) {
      event.preventDefault()
    }
  }

  updateSwipeDirectionLock(clientX, clientY) {
    const dx = clientX - this.swipeStartX
    const dy = clientY - this.swipeStartY

    if (
      this.swipeLockedHorizontal === null &&
      (Math.abs(dx) > SWIPE_DIRECTION_LOCK_PX || Math.abs(dy) > SWIPE_DIRECTION_LOCK_PX)
    ) {
      this.swipeLockedHorizontal = Math.abs(dx) >= Math.abs(dy)
    }
  }

  /** @returns {boolean} whether a slide change was applied */
  finishSwipeFromDeltas(dx, dy, event) {
    const dominantX =
      Math.abs(dx) >= SWIPE_THRESHOLD_PX && Math.abs(dx) >= Math.abs(dy) * 0.65

    // Chrome often omits pointermove/touchmove during a quick drag; do not require a prior axis lock.
    const allow =
      dominantX && this.swipeLockedHorizontal !== false

    if (!allow) {
      this.swipeLockedHorizontal = null
      return false
    }

    if (dx > 0) {
      this.prev(event)
    } else {
      this.next(event)
    }
    this.suppressClickUntil = performance.now() + 450
    this.swipeLockedHorizontal = null
    return true
  }

  onSwipeClickCapture(event) {
    if (this.slideTargets.length < 2) return
    if (performance.now() < this.suppressClickUntil && !this.swipeTargetIsControl(event.target)) {
      event.preventDefault()
      event.stopImmediatePropagation()
    }
  }

}
