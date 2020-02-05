/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

import * as ipfs from  "./ipfs.js"
// TODO: import "./web_modules/it-to-stream.js"
import "./web_modules/render-media.js"


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
  container.innerHTML = ""

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

    // Style iframe content
    // TODO: Doesn't work
    if (elem && elem.tagName === "IFRAME") {
      elem.sandbox += " allow-same-origin"

      const doc = elem.contentDocument
      const link = document.createElement("link")
      link.rel = "stylesheet"
      link.href = "application.css"
      link.type = "text/css"

      doc.head.appendChild(link)
      doc.body.className = "text-gray-100 dark:text-gray-500"
    }
  })
}


function reportIpfsError(err) {
  app.ports.ipfsGotError.send(err.message || err)
}
