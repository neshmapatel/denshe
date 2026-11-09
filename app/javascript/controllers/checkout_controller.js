import { Controller } from "@hotwired/stimulus"

// Hides the billing address while it matches the shipping address.
// When an admin waives shipping for an offline sale, the summary updates live.
export default class extends Controller {
  static targets = [ "billing", "same", "waive", "shippingLabel", "due" ]
  static values = {
    shippingLabel: String,
    complimentaryLabel: String,
    dueWithShipping: String,
    dueWithoutShipping: String
  }

  connect() {
    this.sync()
    this.syncShipping()
  }

  sync() {
    if (!this.hasBillingTarget || !this.hasSameTarget) return

    this.billingTarget.hidden = this.sameTarget.checked
  }

  syncShipping() {
    if (!this.hasWaiveTarget) return

    const waived = this.waiveTarget.checked
    if (this.hasShippingLabelTarget) {
      this.shippingLabelTarget.textContent = waived
        ? (this.complimentaryLabelValue || "Complimentary")
        : this.shippingLabelValue
    }
    if (this.hasDueTarget) {
      this.dueTarget.textContent = waived
        ? this.dueWithoutShippingValue
        : this.dueWithShippingValue
    }
  }
}
