/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

import "./analytics.js"
import * as ipfs from "./ipfs.js"
import * as media from "./media.js"



// | (• ◡•)| (❍ᴥ❍ʋ)


const app = Elm.Main.init({
  node: document.getElementById("elm"),
  flags: {
    roots: roots()
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


app.ports.ipfsListDirectory.subscribe(({ cid, pathSegments }) => {
  ipfs.listDirectory(cid)
    .then(results => {
      app.ports.ipfsGotDirectoryList.send({
        pathSegments,
        results
      })
    })
    .catch(reportIpfsError)
})


app.ports.ipfsResolveAddress.subscribe(async address => {
  const resolvedResult = await ipfs.replaceDnsLinkInAddress(address)
  app.ports.ipfsGotResolvedAddress.send(resolvedResult)
})


app.ports.ipfsSetup.subscribe(_ => {
  ipfs.setup()
    .then(app.ports.ipfsCompletedSetup.send)
    .catch(reportIpfsError)
})


app.ports.removeStoredRoots.subscribe(_ => {
  localStorage.removeItem("fissionDrive.roots")
})


app.ports.renderMedia.subscribe(opts => {
  // Wait for DOM to render
  // TODO: Needs improvement, should use MutationObserver instead of port.
  setTimeout(_ => media.render(opts), 250)
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


app.ports.storeRoots.subscribe(roots => {
  localStorage.setItem("fissionDrive.roots", JSON.stringify(roots))
})



// 🛠
// -

function reportIpfsError(err) {
  app.ports.ipfsGotError.send(err.message || err)
  console.error(err)
}


function roots() {
  const stored = localStorage.getItem("fissionDrive.roots")
  return stored ? JSON.parse(stored) : null
}
