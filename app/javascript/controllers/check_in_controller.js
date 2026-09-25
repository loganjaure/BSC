import { Controller } from "@hotwired/stimulus"

const TIMEOUT_MS = 10000

export default class extends Controller {
  static targets = ["button", "label", "spinner", "status", "check"]
  static values = { url: String, checkedIn: Boolean }
  // AC-04.2: if already checked in, button loads disabled
  connect() {
    // Already checked in (page reload / came back later)
    if (this.checkedInValue) this.showSuccess()
  }

  async submit() {
    if (this.checkedInValue || this.busy) return
    this.busy = true
    this.showLoading()

    const abort = new AbortController()
    const timer = setTimeout(() => abort.abort(), TIMEOUT_MS)

    try {
      const res = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        credentials: "same-origin",
        signal: abort.signal
      })
      const data = await res.json().catch(() => ({}))

      // Only show success if the server confirms the row was saved
      // AC-04.3: only confirm once the server says attendance was saved
      if (res.ok && data.checked_in) {
        this.checkedInValue = true
        this.showSuccess()
      } else {
        this.showError(data.error || "Check-in wasn't saved. Try again.")
      }
    } catch (err) {
      this.showError(err.name === "AbortError"
        ? "Check-in timed out. Try again."
        : "Couldn't reach the server. Check your connection and try again.")
    } finally {
      clearTimeout(timer)
      this.busy = false
    }
  }

  showLoading() {
    this.setButton("is-loading", "Checking in…", true)
    this.spinnerTarget.hidden = false
    this.setStatus("")
    this.checkTarget.hidden = true
  }

  // AC-04.3: visual confirmation (green button + checkmark); AC-04.2: button disabled
  showSuccess() {
    this.setButton("is-checked", "Checked in", true)
    this.spinnerTarget.hidden = true
    this.setStatus("")
    this.checkTarget.hidden = false
  }

  showError(message) {
    this.setButton("", "Try again", false)
    this.spinnerTarget.hidden = true
    this.setStatus(message, true)
  }

  setButton(state, text, disabled) {
    this.buttonTarget.className = `bsc-checkin-btn ${state}`.trim()
    this.buttonTarget.disabled = disabled
    this.labelTarget.textContent = text
  }

  setStatus(text, isError = false) {
    this.statusTarget.textContent = text
    this.statusTarget.classList.toggle("is-error", isError)
  }
}
