import { Controller } from "@hotwired/stimulus"

// Pieces saved on this device. The drawer, the full page, and every heart
// read the same list.
export default class extends Controller {
  static targets = [ "count", "list", "empty", "template", "share", "summary", "toast" ]
  static values = { whatsapp: String, email: String, mark: String }

  connect() {
    this.items = this.read()
    this.render()
  }

  disconnect() {
    clearTimeout(this.toastTimer)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const item = {
      slug: event.params.slug,
      name: event.params.name,
      price: event.params.price,
      url: event.params.url,
      image: event.params.image || null
    }
    if (!item.slug) return

    const exists = this.items.some((saved) => saved.slug === item.slug)
    this.items = exists ? this.items.filter((saved) => saved.slug !== item.slug) : [ item, ...this.items ]
    this.persist()
    this.render()
    this.announce(exists ? "Removed from your jewellery box" : "Tucked into your jewellery box")
  }

  remove(event) {
    event.preventDefault()
    this.items = this.items.filter((saved) => saved.slug !== event.params.slug)
    this.persist()
    this.render()
    this.announce("Removed from your jewellery box")
  }

  read() {
    try {
      const parsed = JSON.parse(localStorage.getItem(this.storageKey) || "[]")
      return Array.isArray(parsed) ? parsed.filter((item) => item?.slug) : []
    } catch (_error) {
      return []
    }
  }

  persist() {
    localStorage.setItem(this.storageKey, JSON.stringify(this.items))
  }

  render() {
    const saved = new Set(this.items.map((item) => item.slug))

    this.countTargets.forEach((node) => {
      node.textContent = String(this.items.length)
      node.hidden = this.items.length === 0
    })

    this.emptyTargets.forEach((node) => {
      node.hidden = this.items.length > 0
    })

    this.listTargets.forEach((list) => {
      list.replaceChildren()
      this.items.forEach((item) => list.append(this.row(item)))
      list.hidden = this.items.length === 0
    })

    this.shareTargets.forEach((node) => {
      const href = this.shareHref()
      node.hidden = this.items.length === 0
      if (!href) return
      node.href = href
      if (href.startsWith("http")) {
        node.target = "_blank"
        node.rel = "noopener"
      } else {
        node.removeAttribute("target")
      }
    })

    if (this.hasSummaryTarget) {
      const count = this.items.length
      this.summaryTargets.forEach((node) => {
        node.textContent = count === 0
          ? "Nothing tucked away yet."
          : `${count} ${count === 1 ? "piece" : "pieces"} waiting.`
      })
    }

    document.querySelectorAll("[data-save-toggle]").forEach((button) => {
      const slug = button.dataset.jewelleryBoxSlugParam
      const on = saved.has(slug)
      button.setAttribute("aria-pressed", on ? "true" : "false")
      const name = button.dataset.jewelleryBoxNameParam
      const label = button.querySelector("[data-save-label]")
      if (label) {
        label.textContent = on ? "In your jewellery box" : "Tuck into your jewellery box"
        button.setAttribute("aria-label", `${label.textContent}: ${name || ""}`.trim())
      } else if (name) {
        button.setAttribute(
          "aria-label",
          on ? `Remove ${name} from your jewellery box` : `Save ${name} to your jewellery box`
        )
      }
    })
  }

  row(item) {
    const fragment = this.templateTarget.content.cloneNode(true)
    const link = fragment.querySelector("[data-slot='link']")
    const nameLink = fragment.querySelector("[data-slot='name-link']")
    const price = fragment.querySelector("[data-slot='price']")
    const image = fragment.querySelector("[data-slot='image']")
    const remove = fragment.querySelector("[data-slot='remove']")

    link.href = item.url
    nameLink.href = item.url
    nameLink.textContent = item.name
    price.textContent = item.price

    if (item.image) {
      image.src = item.image
    } else if (this.markValue) {
      image.src = this.markValue
      image.classList.add("is-mark")
    }
    image.alt = ""
    remove.dataset.jewelleryBoxSlugParam = item.slug
    return fragment
  }

  shareHref() {
    if (this.items.length === 0) return null

    const lines = this.items.map((item, index) => `${index + 1}. ${item.name}, ${item.price}\n${item.url}`)
    const text = `Hello DeNshe, please hold these pieces for me:\n\n${lines.join("\n\n")}`
    if (this.whatsappValue) return `https://wa.me/${this.whatsappValue}?text=${encodeURIComponent(text)}`

    return `mailto:${this.emailValue}?subject=${encodeURIComponent("My jewellery box")}&body=${encodeURIComponent(text)}`
  }

  announce(message) {
    if (!this.hasToastTarget) return
    this.toastTarget.textContent = message
    this.toastTarget.hidden = false
    clearTimeout(this.toastTimer)
    this.toastTimer = setTimeout(() => {
      this.toastTarget.hidden = true
    }, 2400)
  }

  get storageKey() {
    return "denshe.jewellery-box"
  }
}
