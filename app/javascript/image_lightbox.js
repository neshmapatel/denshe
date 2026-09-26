function startLightbox() {
  const dialog = document.querySelector("[data-lightbox]")
  if (!dialog || dialog.dataset.ready === "true") return

  dialog.dataset.ready = "true"
  const image = dialog.querySelector("[data-lightbox-image]")

  document.addEventListener("click", (event) => {
    const trigger = event.target.closest("[data-fullscreen-src]")
    if (!trigger) return

    image.src = trigger.getAttribute("data-fullscreen-src")
    image.alt = trigger.getAttribute("data-fullscreen-alt") || ""
    if (!dialog.open) dialog.showModal()
    document.dispatchEvent(new CustomEvent("lightbox:open"))
  })

  dialog.addEventListener("click", (event) => {
    if (event.target === dialog || event.target.closest("[data-lightbox-close]")) dialog.close()
  })

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && dialog.open) dialog.close()
  })

  dialog.addEventListener("close", () => {
    image.removeAttribute("src")
    document.dispatchEvent(new CustomEvent("lightbox:close"))
  })
}

document.addEventListener("DOMContentLoaded", startLightbox)
document.addEventListener("turbo:load", startLightbox)
if (document.readyState !== "loading") startLightbox()
