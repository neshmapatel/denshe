import { Controller } from "@hotwired/stimulus"

// Server flash notices (e.g. "X is selected") dismiss themselves after a beat.
export default class extends Controller {
  static values = { delay: { type: Number, default: 3200 } }

  connect() {
    this.timer = window.setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    if (this.timer) window.clearTimeout(this.timer)
  }

  dismiss() {
    this.element.classList.add("flash-stack--out")
    window.setTimeout(() => this.element.remove(), 350)
  }
}
