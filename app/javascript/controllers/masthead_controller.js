import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.onScroll = () => {
      this.element.dataset.stuck = window.scrollY > 8 ? "true" : "false"
    }
    this.onScroll()
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }
}
