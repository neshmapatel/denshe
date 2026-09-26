import { Controller } from "@hotwired/stimulus"

// The track holds a copy of the last photo at the start and the first photo
// at the end. Scrolling onto either copy jumps back to the real photo, so the
// row never reaches an end.
export default class extends Controller {
  static targets = [ "track", "slide", "thumb" ]
  static values = { count: Number }

  connect() {
    this.looping = this.countValue > 1 && this.slideTargets.length > this.countValue
    if (!this.hasTrackTarget) return

    this.onScroll = () => {
      window.clearTimeout(this.settleTimer)
      this.settleTimer = window.setTimeout(() => this.settle(), 90)
    }
    this.trackTarget.addEventListener("scroll", this.onScroll, { passive: true })
    this.onLightboxOpen = () => this.pause()
    this.onLightboxClose = () => this.play()
    document.addEventListener("lightbox:open", this.onLightboxOpen)
    document.addEventListener("lightbox:close", this.onLightboxClose)

    if (this.looping) this.scrollTo(1, false)
    this.play()
  }

  disconnect() {
    this.pause()
    window.clearTimeout(this.settleTimer)
    if (this.hasTrackTarget) this.trackTarget.removeEventListener("scroll", this.onScroll)
    document.removeEventListener("lightbox:open", this.onLightboxOpen)
    document.removeEventListener("lightbox:close", this.onLightboxClose)
  }

  next(event) {
    event?.preventDefault()
    this.step(1)
  }

  previous(event) {
    event?.preventDefault()
    this.step(-1)
  }

  show(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.pause()
    this.scrollTo(this.looping ? index + 1 : index, true)
    this.play()
  }

  key(event) {
    if (event.key !== "ArrowRight" && event.key !== "ArrowLeft") return
    if (this.countValue < 2) return

    event.preventDefault()
    this.step(event.key === "ArrowRight" ? 1 : -1)
  }

  play() {
    this.pause()
    if (!this.looping) return
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.timer = window.setInterval(() => this.step(1), 4500)
  }

  pause() {
    if (this.timer) window.clearInterval(this.timer)
    this.timer = null
  }

  step(delta) {
    if (!this.hasTrackTarget || this.slideTargets.length < 2) return

    this.scrollTo(this.nearest() + delta, true)
  }

  settle() {
    if (!this.looping || this.correcting) return

    const index = this.nearest()
    const last = this.slideTargets.length - 1
    if (index === 0) {
      this.scrollTo(last - 1, false)
      this.mark(this.countValue - 1)
    } else if (index === last) {
      this.scrollTo(1, false)
      this.mark(0)
    } else {
      this.mark(index - 1)
    }
  }

  nearest() {
    const width = this.slideTargets[0].getBoundingClientRect().width
    if (!width) return this.looping ? 1 : 0

    return Math.round(this.trackTarget.scrollLeft / width)
  }

  scrollTo(index, smooth) {
    const slide = this.slideTargets[index]
    if (!slide) return

    const track = this.trackTarget
    this.correcting = !smooth
    track.style.scrollBehavior = smooth ? "smooth" : "auto"
    track.scrollLeft = slide.offsetLeft
    if (smooth) {
      this.mark(this.looping ? index - 1 : index)
    } else {
      window.requestAnimationFrame(() => {
        track.style.scrollBehavior = ""
        this.correcting = false
      })
    }
  }

  mark(index) {
    const wrapped = ((index % this.countValue) + this.countValue) % this.countValue
    this.thumbTargets.forEach((node, position) => {
      if (position === wrapped) node.setAttribute("aria-current", "true")
      else node.removeAttribute("aria-current")
    })
  }
}
