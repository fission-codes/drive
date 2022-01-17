/*

ヾ(⌐■_■)ノ♪

Everything involving media.

*/

import "./web_modules/it-to-stream.min.js"
import "./web_modules/render-media.min.js"

import * as fs from "./fs.js"
import * as ipfs from "./ipfs.js"


let stream


customElements.define("fission-drive-media",
  class extends HTMLElement {
    constructor() {
      super()
    }

    static get observedAttributes() {
      return [ "name", "path", "useFS" ]
    }

    connectedCallback() {
      clearTimeout(this.timeoutId)
      this.timeoutId = setTimeout(() => this.render(), 500)
    }

    disconnectedCallback() {
      clearTimeout(this.timeoutId)
    }

    attributeChangedCallback(name, oldValue, newValue) {
      if (oldValue === null) return
      if (oldValue !== newValue) this.render()
    }

    render() {
      const name = this.getAttribute("name")
      const path = this.getAttribute("path")
      const useFS = this.getAttribute("useFS") === "true"

      if (path) renderIn({ container: this, name, path, useFS })
    }
  }
);


function renderIn({ container, name, path, useFS }) {
  container.childNodes.forEach(c => {
    container.removeChild(c)
  })

  // Streaming method
  const makeStream = useFS
    ? fs.fakeStream
    : ipfs.stream

  // Initialize stream
  const file = address => ({
    name: name,
    createReadStream: function createReadStream(opts) {
      if (!opts) opts = {}

      const start = opts.start || 0
      const end = opts.end ? start + opts.end + 1 : undefined

      if (stream && stream.destroy) {
        stream.destroy()
      }

      stream = makeStream(address, { offset: start, length: end && end - start })
      stream.on("error", console.error)

      return stream
    }
  })

  // Render stream
  renderMedia.append(file(path), container, (err, elem) => {
    if (err) return console.error(err.message)

    if (elem.tagName === "IMG") {
      elem.addEventListener("load", e => {
        if (e.target.height < 32 || e.target.width < 32) {
          e.target.className = "p-4"
        }
      })
    }

    // For some weird reason Chrome has a rendering issue here
    forceRedraw(container)
    setTimeout(() => forceRedraw(container), 50)
    setTimeout(() => forceRedraw(container), 100)
    setTimeout(() => forceRedraw(container), 200)
    setTimeout(() => forceRedraw(container), 400)
  })
}



// 🛠
// -

function forceRedraw(node) {
  if (!node) return
  node.parentNode.style["min-height"] = node.parentNode.offsetHeight + "px"
  node.style.display = "none"
  node.offsetHeight
  node.style.display = ""
  setTimeout(_ => node.parentNode.style["min-height"] = "", 0)
}
