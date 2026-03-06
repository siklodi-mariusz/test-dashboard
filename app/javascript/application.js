// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

Turbo.StreamActions.reload_frame = function () {
  const frame = document.getElementById(this.getAttribute("target"))
  if (!frame) return

  if (frame.src) {
    frame.reload()
  } else if (frame.dataset.reloadUrl) {
    frame.src = frame.dataset.reloadUrl
  }
}
