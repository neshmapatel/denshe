import { Controller } from "@hotwired/stimulus"

// Owns the three overlays that share a scrim: the mobile menu, the search
// panel, and the jewellery box drawer. Only one can be open at a time.
export default class extends Controller {
  static targets = ["menu", "search", "saved", "scrim", "searchInput"]

  connect() {
    this.openName = null
    this.trigger = null
    this.panels().forEach((panel) => this.setClosed(panel))
    this.scrimTarget.dataset.open = "false"
  }

  disconnect() {
    this.unlockScroll()
  }

  toggleMenu(event) {
    this.toggle("menu", event.currentTarget)
  }

  toggleSearch(event) {
    this.toggle("search", event.currentTarget)
  }

  toggleSaved(event) {
    this.toggle("saved", event.currentTarget)
  }

  keydown(event) {
    if (event.key === "Escape") this.close()
  }

  close() {
    if (!this.openName) return

    const panel = this[`${this.openName}Target`]
    this.setClosed(panel)
    this.scrimTarget.dataset.open = "false"
    this.unlockScroll()

    if (this.trigger) {
      this.trigger.setAttribute("aria-expanded", "false")
      this.trigger.focus()
    }

    this.openName = null
    this.trigger = null
  }

  toggle(name, trigger) {
    const wasOpen = this.openName === name
    this.close()
    if (wasOpen) return

    const panel = this[`${name}Target`]
    panel.removeAttribute("inert")
    panel.dataset.open = "true"
    this.scrimTarget.dataset.open = "true"
    this.lockScroll()

    trigger.setAttribute("aria-expanded", "true")
    this.openName = name
    this.trigger = trigger

    // Wait for the panel to become visible before moving focus into it.
    requestAnimationFrame(() => {
      const focusable = name === "search" && this.hasSearchInputTarget
        ? this.searchInputTarget
        : panel.querySelector("a, button, input, [tabindex]")
      focusable?.focus()
    })
  }

  setClosed(panel) {
    panel.dataset.open = "false"
    panel.setAttribute("inert", "")
  }

  panels() {
    return [
      this.hasMenuTarget && this.menuTarget,
      this.hasSearchTarget && this.searchTarget,
      this.hasSavedTarget && this.savedTarget
    ].filter(Boolean)
  }

  lockScroll() {
    document.documentElement.style.overflow = "hidden"
  }

  unlockScroll() {
    document.documentElement.style.overflow = ""
  }
}
