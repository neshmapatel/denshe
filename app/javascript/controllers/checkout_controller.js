import { Controller } from "@hotwired/stimulus"

// Hides the billing address while it matches the shipping address.
export default class extends Controller {
  static targets = [ "billing", "same" ]

  connect() {
    this.sync()
  }

  sync() {
    if (!this.hasBillingTarget || !this.hasSameTarget) return

    this.billingTarget.hidden = this.sameTarget.checked
  }
}
