import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "stage", "thumb" ]

  show(event) {
    const thumb = event.currentTarget
    const image = this.stageTarget.querySelector("img")
    if (image && thumb.dataset.full) {
      image.src = thumb.dataset.full
    }
    this.thumbTargets.forEach((node) => {
      node.setAttribute("aria-current", node === thumb ? "true" : "false")
    })
  }

  key(event) {
    if (event.key !== "ArrowRight" && event.key !== "ArrowLeft") return
    if (!this.hasThumbTarget) return

    const current = this.thumbTargets.findIndex((node) => node.getAttribute("aria-current") === "true")
    const next = event.key === "ArrowRight" ? current + 1 : current - 1
    const thumb = this.thumbTargets[next]
    if (!thumb) return

    event.preventDefault()
    thumb.click()
    thumb.focus()
  }
}
