import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "initialFocus"]

  connect() {
    if (this.hasInitialFocusTarget) this.initialFocusTarget.focus()
  }

  close() {
    this.element.remove()
  }

  closeOnBackdrop(event) {
    if (!this.dialogTarget.contains(event.target)) {
      this.close()
    }
  }
}
