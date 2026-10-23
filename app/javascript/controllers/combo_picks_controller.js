import { Controller } from "@hotwired/stimulus"

// A look asks for a fixed number of pieces. Once that many are chosen, the
// rest stay closed until one is let go.
export default class extends Controller {
  static targets = [ "group", "count", "submit", "statusText" ]

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
    let totalNeeded = 0
    let totalSelected = 0

    this.groupTargets.forEach((group) => {
      const limit = Number(group.dataset.limit)
      totalNeeded += limit
      const boxes = this.boxes(group)
      const checked = boxes.filter((box) => box.checked)
      totalSelected += checked.length
      if (checked.length !== limit) ready = false

      const count = group.querySelector("[data-combo-picks-target='count']")
      if (count) {
        if (checked.length === 0) {
          count.textContent = `Choose ${limit}`
          count.classList.remove("is-complete", "is-partial")
        } else if (checked.length < limit) {
          count.textContent = `${checked.length} of ${limit} · pick ${limit - checked.length} more`
          count.classList.add("is-partial")
          count.classList.remove("is-complete")
        } else {
          count.textContent = `✓ ${checked.length} of ${limit} selected`
          count.classList.add("is-complete")
          count.classList.remove("is-partial")
        }
      }

      const full = boxes.some((box) => box.type === "checkbox") && checked.length >= limit
      boxes.forEach((box) => {
        const capped = full && box.type === "checkbox" && !box.checked
        box.disabled = capped
        const label = box.closest("label")
        if (label) {
          label.classList.toggle("combo-pick--full", capped)
          label.classList.toggle("combo-pick--selected", box.checked)
        }
      })
    })

    if (this.hasStatusTextTarget) {
      if (ready) {
        this.statusTextTarget.textContent = `✓ All ${totalSelected} pieces selected · Ready to add!`
      } else {
        const remaining = totalNeeded - totalSelected
        this.statusTextTarget.textContent = `${totalSelected} of ${totalNeeded} pieces picked · ${remaining} more needed`
      }
    }

    if (this.hasSubmitTarget) this.submitTarget.disabled = !ready
  }

  boxes(group) {
    return [ ...group.querySelectorAll("input[type='checkbox'], input[type='radio']") ]
  }
}
