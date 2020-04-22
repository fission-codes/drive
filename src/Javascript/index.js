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

window.sdk = sdk



// | (• ◡•)| (❍ᴥ❍ʋ)


const app = Elm.Main.init({
  node: document.getElementById("elm"),
  flags: {
    authenticated: authenticated(),
    foundation: foundation(),
    viewportSize: { height: window.innerHeight, width: window.innerWidth }
  }
})



// Ports
// =====

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


app.ports.removeStoredAuthDnsLink.subscribe(_ => {
  localStorage.removeItem("fissionDrive.authlink")
})


app.ports.removeStoredFoundation.subscribe(_ => {
  localStorage.removeItem("fissionDrive.foundation")
})


app.ports.renderMedia.subscribe(a => {
  // Wait for DOM to render
  // TODO: Needs improvement, should use MutationObserver instead of port.
  setTimeout(_ => media.render(a), 250)
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


app.ports.storeAuthDnsLink.subscribe(dnsLink => {
  localStorage.setItem("fissionDrive.authlink", dnsLink)
})


app.ports.storeFoundation.subscribe(foundation => {
  localStorage.setItem("fissionDrive.foundation", JSON.stringify(foundation))
})


// FS
// --

const exe = (port, method, options = {}) => app.ports[port].subscribe(async a => {
  const results = await fs[method]({ ...a, ...options })

  app.ports.ipfsGotDirectoryList.send({
    pathSegments: a.pathSegments.slice(0, options.listParent ? -1 : undefined),
    results
  })
})


const syncHook = cid => {
  app.ports.ipfsReplaceResolvedAddress.send({ cid })
}


exe("fsAddContent", "add")
exe("fsCreateDirectory", "createDirecory", { listParent: true })
exe("fsListDirectory", "listDirectory")
exe("fsLoad", "load", { syncHook })
exe("fsRemoveItem", "removeItem", { listParent: true })


// IPFS
// ----

app.ports.ipfsListDirectory.subscribe(({ address, pathSegments }) => {
  ipfs.listDirectory(address)
    .then(results => app.ports.ipfsGotDirectoryList.send({ pathSegments, results }))
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


// User
// ----

app.ports.annihilateKeys.subscribe(_ => {
  sdk.keystore.clear()
})


app.ports.checkIfUsernameIsAvailable.subscribe(async username => {
  if (sdk.user.isUsernameValid(username)) {
    const isAvailable = await sdk.user.isUsernameAvailable(username)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
})


app.ports.createAccount.subscribe(async userProps => {
  let response

  try {
    response = await sdk.user.createAccount(userProps, api.endpoint)
  } catch (_) {
    response = { status: 500 }
  }

  if (response.status < 300) {
    const dnsLink = `${userProps.username}.fission.name`

    localStorage.setItem("fissionDrive.authlink", dnsLink)

    await fs.createNew()
    await fs.addSampleData()
    await fs.updateRoot()

    app.ports.gotCreateAccountSuccess.send({
      dnsLink
    })

    app.ports.ipfsGotResolvedAddress.send({
      isDnsLink: true,
      resolved: await fs.cid(),
      unresolved: dnsLink
    })

  } else {
    app.ports.gotCreateAccountFailure.send(
      "Unable to create an account, maybe you have one already?"
    )

  }
})



// 🛠
// ==

function authenticated() {
  const stored = localStorage.getItem("fissionDrive.authlink")
  return stored ? { dnsLink: stored } : null
}


function reportIpfsError(err) {
  app.ports.ipfsGotError.send(err.message || err)
  console.error(err)
}


function foundation() {
  const stored = localStorage.getItem("fissionDrive.foundation")
  return stored ? JSON.parse(stored) : null
}
