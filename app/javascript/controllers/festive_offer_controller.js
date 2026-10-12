import { Controller } from "@hotwired/stimulus"

// The festive poster shows once per visit. Cancel, or leaving for the shop, keeps it closed.
export default class extends Controller {
  connect() {
    if (window.sessionStorage.getItem("denshe-festive-offer") === "closed") {
      this.element.remove()
      return
    }

    this.element.showModal()
    this.onCancel = () => {
      window.sessionStorage.setItem("denshe-festive-offer", "closed")
    }
    this.element.addEventListener("cancel", this.onCancel)
  }

  disconnect() {
    if (this.onCancel) this.element.removeEventListener("cancel", this.onCancel)
  }

  close(event) {
    if (event?.type === "click" && event.currentTarget?.tagName === "BUTTON") event.preventDefault()
    window.sessionStorage.setItem("denshe-festive-offer", "closed")
    this.element.close()
  }
}
