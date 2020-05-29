/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

import "./web_modules/tocca.js"
import sdk from "./web_modules/fission-sdk.js"

import "./analytics.js"
import "./custom.js"

import * as api from "./api.js"
import * as fs from "./fs.js"
import * as ipfs from "./ipfs.js"
import * as media from "./media.js"



// | (• ◡•)| (❍ᴥ❍ʋ)


let app


sdk.user.didKey().then(did => {
  // Initialize app
  app = Elm.Main.init({
    node: document.getElementById("elm"),
    flags: {
      authenticated: authenticated(),
      currentTime: Date.now(),
      did: did,
      foundation: foundation(),
      lastFsOperation: lastFsOperation(),
      viewportSize: { height: window.innerHeight, width: window.innerWidth }
    }
  })

  // Ports
  app.ports.copyToClipboard.subscribe(copyToClipboard)
  // app.ports.removeStoredAuthEssentials.subscribe(removeStoredAuthEssentials)
  app.ports.removeStoredFoundation.subscribe(removeStoredFoundation)
  app.ports.renderMedia.subscribe(renderMedia)
  app.ports.showNotification.subscribe(showNotification)
  app.ports.storeAuthEssentials.subscribe(storeAuthEssentials)
  app.ports.storeFoundation.subscribe(storeFoundation)

  // Ports (FS)
  exe("fsAddContent", "add")
  exe("fsCreateDirectory", "createDirecory", { listParent: true })
  exe("fsListDirectory", "listDirectory")
  exe("fsLoad", "load", { syncHook })
  exe("fsNew", "createNew", { callback: freshUser, syncHook })
  exe("fsRemoveItem", "removeItem", { listParent: true })

  // Ports (IPFS)
  app.ports.ipfsListDirectory.subscribe(ipfsListDirectory)
  app.ports.ipfsResolveAddress.subscribe(ipfsResolveAddress)
  app.ports.ipfsSetup.subscribe(ipfsSetup)
})



// Ports
// =====

function copyToClipboard(text) {
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
}


// function removeStoredAuthEssentials(_) {
//   localStorage.removeItem("fissionDrive.auth")
// }


function removeStoredFoundation(_) {
  localStorage.removeItem("fissionDrive.foundation")
}


function renderMedia(a) {
  // Wait for DOM to render
  // TODO: Needs improvement, should use MutationObserver instead of port.
  setTimeout(_ => media.render(a), 250)
}


function showNotification(text) {
  if (Notification.permission === "granted") {
    new Notification(text)

  } else if (Notification.permission !== "denied") {
    Notification.requestPermission().then(function (permission) {
      if (permission === "granted") new Notification(text)
    })

  }
}


function storeAuthEssentials(details) {
  localStorage.setItem("fissionDrive.auth", JSON.stringify(details))
}


function storeFoundation(foundation) {
  localStorage.setItem("fissionDrive.foundation", JSON.stringify(foundation))
}


// FS
// --

function exe(port, method, options = {}) {
  app.ports[port].subscribe(async a => {
    let args = { pathSegments: [], ...a, ...options }
    let results

    try {
      results = await fs[method](args)

      app.ports.ipfsGotDirectoryList.send({
        pathSegments: fs.removePrivatePrefix(
          args.pathSegments.slice(0, options.listParent ? -1 : undefined)
        ),
        results
      })

    } catch (e) {
      reportFileSystemError(e)

    }
  })
}


async function freshUser({ cid, dnsLink }) {
  app.ports.ipfsGotResolvedAddress.send({
    isDnsLink: true,
    resolved: cid,
    unresolved: dnsLink
  })
}


async function syncHook(cid) {
  app.ports.ipfsReplaceResolvedAddress.send({ cid })
  localStorage.setItem("fissionDrive.lastFsOperation", Date.now().toString())
  console.log("Syncing …", cid)
  await fs.updateRoot()
}


// IPFS
// ----

function ipfsListDirectory({ address, pathSegments }) {
  ipfs.listDirectory(address)
    .then(results => app.ports.ipfsGotDirectoryList.send({ pathSegments, results }))
    .catch(reportIpfsError)
}


async function ipfsResolveAddress(address) {
  const resolvedResult = await ipfs.replaceDnsLinkInAddress(address)

  console.log("resolved!", resolvedResult)

  if (resolvedResult.resolved) {
    app.ports.ipfsGotResolvedAddress.send(resolvedResult)

  } else {
    const cachedFoundation = foundation()
    cachedFoundation && app.ports.ipfsGotResolvedAddress.send(cachedFoundation)

  }
}


function ipfsSetup(_) {
  ipfs.setup()
    .then(app.ports.ipfsCompletedSetup.send)
    .catch(reportIpfsError)
}


// User
// ----

// function annihilateKeys(_) {
//   sdk.keystore.clear()
// })



// 🛠
// ==

tocca({
  dbltapThreshold: 400,
  tapThreshold: 250
})


function authenticated() {
  const stored = localStorage.getItem("fissionDrive.auth")
  return stored ? JSON.parse(stored) : null
}


function foundation() {
  const stored = localStorage.getItem("fissionDrive.foundation")
  return stored ? JSON.parse(stored) : null
}


function lastFsOperation() {
  return parseInt(localStorage.getItem("fissionDrive.lastFsOperation") || "0", 10)
}


function reportFileSystemError(err) {
  app.ports.fsGotError.send(err.message || err || "")
  console.error(err)
}


function reportIpfsError(err) {
  app.ports.ipfsGotError.send(err.message || err)
  console.error(err)
}
