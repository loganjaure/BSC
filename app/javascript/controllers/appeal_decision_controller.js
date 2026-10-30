import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  disable() {
    this.buttonTargets.forEach((button) => { button.disabled = true })
  }

  enable() {
    this.buttonTargets.forEach((button) => { button.disabled = false })
  }
}
