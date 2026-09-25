import { Controller } from "@hotwired/stimulus"

// A short consultation. Nothing is stored; the last step opens WhatsApp or email.
export default class extends Controller {
  static targets = [ "step", "progress", "bar", "error", "back", "next", "review", "letter", "send", "note" ]
  static values = { whatsapp: String, email: String, price: String }

  connect() {
    this.index = 0
    this.state = {}
    this.moved = false
    this.element.querySelectorAll(".choice").forEach((button) => {
      if (!button.hasAttribute("aria-pressed")) button.setAttribute("aria-pressed", "false")
    })
    this.show()
  }

  pick(event) {
    const { group, value, label } = event.params
    const step = event.currentTarget.closest("[data-fitting-target='step']")
    const current = this.state[group] || []

    if (step.dataset.multiple === "true") {
      const exists = current.some((item) => item.value === value)
      this.state[group] = exists
        ? current.filter((item) => item.value !== value)
        : [ ...current, { value, label } ]
    } else {
      this.state[group] = [ { value, label } ]
    }

    this.paint(step, group)
    this.errorTarget.hidden = true
  }

  next() {
    if (this.reviewing) return

    const step = this.stepTargets[this.index]
    const group = step.dataset.group
    if (step.dataset.required === "true" && !(this.state[group] || []).length) {
      this.errorTarget.hidden = false
      return
    }

    this.index += 1
    this.moved = true
    this.show()
  }

  back() {
    if (this.index === 0) return
    this.index -= 1
    this.moved = true
    this.show()
  }

  send(event) {
    if (!this.sendTarget.getAttribute("href") || this.sendTarget.getAttribute("href") === "#") {
      event.preventDefault()
    }
  }

  show() {
    const reviewing = this.reviewing
    this.stepTargets.forEach((step, index) => {
      step.hidden = reviewing || index !== this.index
    })
    this.reviewTarget.hidden = !reviewing
    this.nextTarget.hidden = reviewing
    this.sendTarget.hidden = !reviewing
    this.backTarget.hidden = this.index === 0
    this.errorTarget.hidden = true

    if (reviewing) {
      this.compose()
      this.progressTarget.textContent = "Your note"
      this.barTarget.style.width = "100%"
    } else {
      const step = this.stepTargets[this.index]
      const number = String(this.index + 1).padStart(2, "0")
      const total = String(this.stepTargets.length).padStart(2, "0")
      this.progressTarget.textContent = `${number} / ${total} · ${step.dataset.label}`
      this.barTarget.style.width = `${(this.index / this.stepTargets.length) * 100}%`
      if (this.moved) {
        const heading = step.querySelector("h2")
        if (heading) {
          heading.tabIndex = -1
          heading.focus()
        }
      }
    }
  }

  paint(step, group) {
    const chosen = new Set((this.state[group] || []).map((item) => item.value))
    step.querySelectorAll("[data-fitting-value-param]").forEach((button) => {
      const value = button.getAttribute("data-fitting-value-param")
      button.setAttribute("aria-pressed", chosen.has(value) ? "true" : "false")
    })
  }

  compose() {
    const labels = (group) => (this.state[group] || []).map((item) => item.label)
    const list = this.sentenceList(labels("pieces"))
    const finish = this.sentenceList(labels("finish"))
    const bits = [ labels("recipient")[0], labels("personality")[0] ]
    if (list) bits.push(`leaning toward ${list}`)
    if (finish) bits.push(`in ${finish}`)
    bits.push(labels("occasion")[0])

    let letter = `${bits.filter(Boolean).join(", ")}.`
    letter = letter.charAt(0).toUpperCase() + letter.slice(1)
    const note = this.hasNoteTarget ? this.noteTarget.value.trim() : ""
    if (note) letter = `${letter} ${note}`

    this.letterTarget.textContent = letter

    const message = [
      `Hello DeNshe, I would like a mystery box (from ${this.priceValue}).`,
      "",
      letter,
      "",
      "Please tell me what you would choose, and how to pay."
    ].join("\n")

    const href = this.whatsappValue
      ? `https://wa.me/${this.whatsappValue}?text=${encodeURIComponent(message)}`
      : `mailto:${this.emailValue}?subject=${encodeURIComponent("A mystery box")}&body=${encodeURIComponent(message)}`

    this.sendTarget.href = href
    if (href.startsWith("http")) {
      this.sendTarget.target = "_blank"
      this.sendTarget.rel = "noopener"
    }
  }

  sentenceList(items) {
    if (items.length <= 1) return items[0] || ""
    if (items.length === 2) return `${items[0]} and ${items[1]}`
    return `${items.slice(0, -1).join(", ")}, and ${items.at(-1)}`
  }

  get reviewing() {
    return this.index >= this.stepTargets.length
  }
}
