import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pill"]
  static classes = ["active", "inactive"]

  select(event) {
    this.pillTargets.forEach(pill => {
      pill.classList.remove(...this.activeClasses)
      pill.classList.add(...this.inactiveClasses)
    })
    event.currentTarget.classList.remove(...this.inactiveClasses)
    event.currentTarget.classList.add(...this.activeClasses)
  }
}
