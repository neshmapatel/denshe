import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "rail", "toggle" ]

  toggle() {
    const open = this.railTarget.dataset.open !== "true"
    this.railTarget.dataset.open = open ? "true" : "false"
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", open ? "true" : "false")
    if (open) this.railTarget.scrollIntoView({ block: "start" })
  }

  sort(event) {
    if (event.target.name !== "sort") return
    event.target.form?.requestSubmit()
  }
}
