import { Controller } from "@hotwired/stimulus"

// Opens Razorpay Standard Checkout for the order already saved on the server.
// UPI QR paid on another phone often never fires the browser handler, so we
// also poll the server (and rely on the Razorpay webhook) until the order is paid.
export default class extends Controller {
  static targets = [ "error" ]
  static values = {
    key: String,
    createUrl: String,
    verifyUrl: String,
    failureUrl: String,
    statusUrl: String
  }

  connect() {
    this.finished = false
    this.pollTimer = null
    if (this.hasStatusUrlValue) this.pollStatus({ quiet: true })
  }

  disconnect() {
    this.stopPolling()
  }

  pay(event) {
    event.preventDefault()
    this.clearError()
    this.finished = false

    fetch(this.createUrlValue, {
      method: "POST",
      credentials: "same-origin",
      headers: this.headers()
    })
      .then((response) => this.read(response))
      .then((order) => this.open(order))
      .catch((error) => this.showError(error.message))
  }

  open(order) {
    if (!window.Razorpay) throw new Error("Payment could not be loaded. Refresh and try again.")

    this.startPolling()

    const checkout = new window.Razorpay({
      key: this.keyValue,
      amount: order.amount,
      currency: order.currency,
      order_id: order.order_id,
      name: "DeNshe",
      handler: (payload) => {
        this.finished = true
        this.stopPolling()
        this.verify(payload)
      },
      modal: {
        ondismiss: () => {
          if (this.finished) return

          this.pollStatus().then((body) => {
            if (body && body.paid) return

            this.stopPolling()
            this.showError("Payment was cancelled. Nothing was charged.")
            this.report({
              status: "cancelled",
              gateway_order_id: order.order_id,
              error_message: "Payment was cancelled. Nothing was charged."
            })
          })
        }
      }
    })

    checkout.on("payment.failed", (response) => {
      this.finished = true
      this.stopPolling()
      const error = (response && response.error) || {}
      const metadata = error.metadata || {}
      const description = error.description || "Payment failed. Nothing was charged."
      this.showError(description)
      this.report({
        status: "failed",
        gateway_order_id: metadata.order_id || order.order_id,
        gateway_payment_id: metadata.payment_id,
        error_code: error.code,
        error_message: description,
        error_source: error.source,
        error_step: error.step,
        error_reason: error.reason
      })
    })
    checkout.open()
  }

  startPolling() {
    this.stopPolling()
    this.pollTimer = window.setInterval(() => this.pollStatus(), 2500)
  }

  stopPolling() {
    if (this.pollTimer) {
      window.clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  pollStatus({ quiet = false } = {}) {
    if (!this.hasStatusUrlValue) return Promise.resolve(null)

    return fetch(this.statusUrlValue, {
      method: "GET",
      credentials: "same-origin",
      headers: { Accept: "application/json" }
    })
      .then((response) => response.json().catch(() => ({})))
      .then((body) => {
        if (body && body.paid) {
          this.finished = true
          this.stopPolling()
          window.location = body.redirect || "/checkout/success"
          return body
        }

        if (body && body.failed) {
          this.finished = true
          this.stopPolling()
          this.showError(body.error || "Payment failed. Nothing was charged.")
        }

        return body
      })
      .catch(() => {
        if (!quiet) return null
        return null
      })
  }

  report(details) {
    fetch(this.failureUrlValue, {
      method: "POST",
      credentials: "same-origin",
      headers: this.headers(),
      body: JSON.stringify(details)
    }).catch(() => {})
  }

  verify(payload) {
    fetch(this.verifyUrlValue, {
      method: "POST",
      credentials: "same-origin",
      headers: this.headers(),
      body: JSON.stringify({
        razorpay_payment_id: payload.razorpay_payment_id,
        razorpay_order_id: payload.razorpay_order_id,
        razorpay_signature: payload.razorpay_signature
      })
    })
      .then((response) => this.read(response))
      .then((body) => { window.location = body.redirect || "/checkout/success" })
      .catch((error) => this.showError(error.message))
  }

  read(response) {
    return response.json().catch(() => ({})).then((body) => {
      if (!response.ok) throw new Error(body.error || "Payment could not be completed.")

      return body
    })
  }

  headers() {
    const token = document.querySelector("meta[name='csrf-token']")

    return {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": token ? token.content : ""
    }
  }

  showError(message) {
    if (!this.hasErrorTarget) return

    this.errorTarget.hidden = false
    this.errorTarget.textContent = message
  }

  clearError() {
    if (!this.hasErrorTarget) return

    this.errorTarget.hidden = true
    this.errorTarget.textContent = ""
  }
}
