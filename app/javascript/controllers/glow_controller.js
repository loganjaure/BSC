import { Controller } from "@hotwired/stimulus"

// Moves the background glow toward the cursor (smoothed), and feeds
// per-element --x/--y to cards + the check-in button for their spotlight.
const SPOTLIGHT = ".bsc-event-card, .bsc-checkin-btn"
const EASE = 0.12

export default class extends Controller {
  connect() {
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.x = this.tx = window.innerWidth / 2
    this.y = this.ty = window.innerHeight * 0.35
    this.apply()

    this.onMove = this.onMove.bind(this)
    this.tick = this.tick.bind(this)
    window.addEventListener("pointermove", this.onMove, { passive: true })
  }

  disconnect() {
    window.removeEventListener("pointermove", this.onMove)
    cancelAnimationFrame(this.raf)
    this.raf = null
  }

  onMove(e) {
    this.tx = e.clientX
    this.ty = e.clientY

    const spot = e.target.closest?.(SPOTLIGHT)
    if (spot) {
      const r = spot.getBoundingClientRect()
      spot.style.setProperty("--x", `${e.clientX - r.left}px`)
      spot.style.setProperty("--y", `${e.clientY - r.top}px`)
    }

    if (this.reduced) {
      this.x = this.tx
      this.y = this.ty
      this.apply()
    } else if (!this.raf) {
      this.raf = requestAnimationFrame(this.tick)
    }
  }

  // Runs only while the glow is catching up, then stops (no idle CPU use)
  tick() {
    this.x += (this.tx - this.x) * EASE
    this.y += (this.ty - this.y) * EASE
    this.apply()

    if (Math.abs(this.tx - this.x) > 0.5 || Math.abs(this.ty - this.y) > 0.5) {
      this.raf = requestAnimationFrame(this.tick)
    } else {
      this.raf = null
    }
  }

  apply() {
    const root = document.documentElement.style
    root.setProperty("--mx", `${this.x}px`)
    root.setProperty("--my", `${this.y}px`)
  }
}