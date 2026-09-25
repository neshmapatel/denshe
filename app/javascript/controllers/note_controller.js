import { Controller } from "@hotwired/stimulus"

// The contact form never posts to the server. It opens the visitor's email app.
export default class extends Controller {
  static values = { email: String }

  send(event) {
    event.preventDefault()
    const data = new FormData(this.element)
    const name = String(data.get("name") || "").trim()
    const message = String(data.get("message") || "").trim()
    const subject = String(data.get("subject") || "Hello from the DeNshe website")
    if (!message) {
      this.element.querySelector("[name='message']")?.focus()
      return
    }

    const body = [ name && `From ${name}`, message ].filter(Boolean).join("\n\n")
    window.location.href = `mailto:${this.emailValue}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`
  }
}
