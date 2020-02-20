/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

import "./web_modules/render-media.js"

import "./analytics.js"
import * as ipfs from "./ipfs.js"


const queryParams =
  (new URL(document.location)).searchParams



// | (• ◡•)| (❍ᴥ❍ʋ)


const app = Elm.Main.init({
  node: document.getElementById("elm"),
  flags: {
    rootCid: localStorage.getItem("fissionDrive.rootCid") || null
  }
})



// Ports
// -----

app.ports.copyToClipboard.subscribe(text => {

  // Insert a textarea element
  const el = document.createElement("textarea")

  el.value = text
  el.setAttribute("readonly", "")
  el.style.position = "absolute"
  el.style.left = "-9999px"

  document.body.appendChild(el)

  // Store original selection
  const selected = document.getSelection().rangeCount > 0
    ? document.getSelection().getRangeAt(0)
    : false

  // Select & copy the text
  el.select()
  document.execCommand("copy")

  // Remove textarea element
  document.body.removeChild(el)

  // Restore original selection
  if (selected) {
    document.getSelection().removeAllRanges()
    document.getSelection().addRange(selected)
  }

})


app.ports.ipfsListDirectory.subscribe(cid => {
  ipfs.listDirectory(cid)
    .then(app.ports.ipfsGotDirectoryList.send)
    .catch(reportIpfsError)
})


app.ports.ipfsSetup.subscribe(_ => {
  ipfs.setup()
    .then(app.ports.ipfsCompletedSetup.send)
    .catch(reportIpfsError)
})


app.ports.removeStoredRootCid.subscribe(_ => {
  localStorage.removeItem("fissionDrive.rootCid")
})


app.ports.renderMedia.subscribe(opts => {
  // Wait for DOM to render
  // TODO: Needs improvement, should use MutationObserver instead of port.
  setTimeout(_ => mediaRenderer(opts), 250)
})


app.ports.showNotification.subscribe(text => {
  if (Notification.permission === "granted") {
    new Notification(text)

  } else if (Notification.permission !== "denied") {
    Notification.requestPermission().then(function (permission) {
      if (permission === "granted") new Notification(text)
    })

  }
})


app.ports.storeRootCid.subscribe(cid => {
  localStorage.setItem("fissionDrive.rootCid", cid)
})



// 🛠
// -

let stream


function mediaRenderer({ id, name, path }) {
  const containerId = id

  // Get container node
  const container = document.getElementById(containerId)
  if (!container) return

  container.childNodes.forEach(c => {
    container.removeChild(c)
  })

  // Initialize stream
  const file = {
    name: name,
    createReadStream: function createReadStream(opts) {
      if (!opts) opts = {}

      const start = opts.start || 0
      const end = opts.end ? start + opts.end + 1 : undefined

      if (stream && stream.destroy) {
        stream.destroy()
      }

      stream = ipfs.stream(path, { offset: start, length: end && end - start })
      stream.on("error", console.error)

      return stream
    }
  }

  // Render stream
  renderMedia.append(file, container, (err, elem) => {
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


function forceRedraw(node) {
  node.parentNode.style["min-height"] = node.parentNode.offsetHeight + "px"
  node.style.display = "none"
  node.offsetHeight
  node.style.display = ""
  setTimeout(_ => node.parentNode.style["min-height"] = "", 0)
}


function reportIpfsError(err) {
  app.ports.ipfsGotError.send(err.message || err)
  console.error(err)
}
