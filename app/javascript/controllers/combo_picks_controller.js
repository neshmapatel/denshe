import { Controller } from "@hotwired/stimulus"

// A look asks for a fixed number of pieces. Once that many are chosen, the
// rest stay closed until one is let go.
export default class extends Controller {
  static targets = [ "group", "count", "submit" ]

  connect() {
    this.refresh()
  }

  change(event) {
    const input = event.target
    if (!(input instanceof HTMLInputElement)) return

    const group = input.closest("[data-combo-picks-target='group']")
    if (!group || input.type !== "checkbox") {
      this.refresh()
      return
    }

    const checked = this.boxes(group).filter((box) => box.checked)
    if (checked.length > Number(group.dataset.limit)) input.checked = false
    this.refresh()
  }

  refresh() {
    let ready = true

    this.groupTargets.forEach((group) => {
      const limit = Number(group.dataset.limit)
      const boxes = this.boxes(group)
      const checked = boxes.filter((box) => box.checked)
      if (checked.length !== limit) ready = false

      const count = group.querySelector("[data-combo-picks-target='count']")
      if (count) {
        count.textContent = checked.length === 0 ? `Choose ${limit}` : `${checked.length} of ${limit}`
      }

      const full = boxes.some((box) => box.type === "checkbox") && checked.length >= limit
      boxes.forEach((box) => {
        const capped = full && box.type === "checkbox" && !box.checked
        box.disabled = capped
        box.closest("label")?.classList.toggle("combo-pick--full", capped)
      })
    })

    if (this.hasSubmitTarget) this.submitTarget.disabled = !ready
  }

  boxes(group) {
    return [ ...group.querySelectorAll("input[type='checkbox'], input[type='radio']") ]
  }
}
