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

import * as endpoints from "./endpoints.js"
import * as fs from "./fs.js"
import * as ipfs from "./ipfs.js"
import * as media from "./media.js"
import { throttle } from "./common.js"


window.sdk = sdk



// | (• ◡•)| (❍ᴥ❍ʋ)


let app


sdk.isAuthenticated().then(props => {
  const { authenticated, newUser, username } = props

  // Initialize app
  app = Elm.Main.init({
    node: document.getElementById("elm"),
    flags: {
      authenticated: authenticated ? { newUser, username } : null,
      currentTime: Date.now(),
      foundation: foundation(),
      lastFsOperation: lastFsOperation(),
      usersDomain: endpoints.users,
      viewportSize: { height: window.innerHeight, width: window.innerWidth }
    }
  })

  // Ports
  app.ports.annihilateKeys.subscribe(annihilateKeys)
  app.ports.copyToClipboard.subscribe(copyToClipboard)
  app.ports.deauthenticate.subscribe(deauthenticate)
  app.ports.redirectToLobby.subscribe(redirectToLobby)
  app.ports.removeStoredFoundation.subscribe(removeStoredFoundation)
  app.ports.renderMedia.subscribe(renderMedia)
  app.ports.showNotification.subscribe(showNotification)
  app.ports.storeFoundation.subscribe(storeFoundation)

  // Ports (FS)
  exe("fsAddContent", "add")
  exe("fsCreateDirectory", "createDirecory", { listParent: true })
  exe("fsListDirectory", "listDirectory")
  exe("fsLoad", "load", { syncHook })
  exe("fsMoveItem", "moveItem", { listParent: true })
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


function deauthenticate() {
  sdk.deauthenticate()
}


function redirectToLobby() {
  sdk.redirectToLobby(undefined, endpoints.lobby)
}


function removeStoredFoundation(_) {
  localStorage.removeItem("fissionDrive.foundation")
  localStorage.removeItem("fissionDrive.lastFsOperation")
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


async function freshUser({ cid, username }) {
  app.ports.ipfsGotResolvedAddress.send({
    isDnsLink: true,
    resolved: cid,
    unresolved: username
  })
}


const syncHook_ = throttle(cid => {
  console.log("Syncing …", cid)

  app.ports.ipfsReplaceResolvedAddress.send({ cid })
  localStorage.setItem("fissionDrive.lastFsOperation", Date.now().toString())

  sdk.updateDataRoot(cid, {
    apiEndpoint: endpoints.api
  })
}, 5000)


function syncHook(cid) {
  return syncHook_(cid)
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

  if (resolvedResult.resolved) {
    app.ports.ipfsGotResolvedAddress.send(resolvedResult)

  } else {
    const cachedFoundation = foundation()

    if (cachedFoundation) {
      app.ports.ipfsGotResolvedAddress.send(cachedFoundation)
    } else {
      window.overrideFileSystem(address)
    }

  }
}


function ipfsSetup(_) {
  ipfs.setup()
    .then(app.ports.ipfsCompletedSetup.send)
    .catch(reportIpfsError)
}


// User
// ----

function annihilateKeys(_) {
  sdk.keystore.clear()
}



// 🛠
// ==

window.overrideFileSystem = (dnsLink) => {
  fs.createNew({
    callback: freshUser,
    pathSegments: [],
    dnsLink,
    syncHook
  })
}


tocca({
  dbltapThreshold: 400,
  tapThreshold: 250
})


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
