/*

ヾ(⌐■_■)ノ♪

Everything involving media.

*/

import "./web_modules/it-to-stream.min.js"
import "./web_modules/render-media.min.js"

import * as fs from "./fs.js"
import * as ipfs from "./ipfs.js"


let stream

customElements.define('fission-drive-media',
  class extends HTMLElement {
    constructor() {
      console.log("created a custom element")
      super()
    }

    connectedCallback() {
      this.render()
    }

    attributeChangedCallback() {
      this.render()
    }

    static get observedAttributes() {
      return ["name", "path", "useFS"]
    }

    render() {
      const name = this.getAttribute("name")
      const path = this.getAttribute("path")
      const useFS = this.getAttribute("useFS") === "true" ? true : false
      renderIn({ container: this, name, path, useFS })
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
  })
}



// 🛠
// -

function forceRedraw(node) {
  node.parentNode.style["min-height"] = node.parentNode.offsetHeight + "px"
  node.style.display = "none"
  node.offsetHeight
  node.style.display = ""
  setTimeout(_ => node.parentNode.style["min-height"] = "", 0)
}
