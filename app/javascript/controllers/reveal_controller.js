import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.nodes = [ ...this.element.querySelectorAll("[data-reveal]") ]
    if (reduce || !("IntersectionObserver" in window)) {
      this.nodes.forEach((node) => { node.dataset.revealed = "true" })
      return
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        const siblings = [ ...entry.target.parentElement.querySelectorAll(":scope > [data-reveal]") ]
        const index = Math.max(siblings.indexOf(entry.target), 0)
        entry.target.style.transitionDelay = `${Math.min(index, 6) * 70}ms`
        entry.target.dataset.revealed = "true"
        this.observer.unobserve(entry.target)
      })
    }, { threshold: 0.12, rootMargin: "0px 0px -8% 0px" })

    this.nodes.forEach((node) => this.observer.observe(node))
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
