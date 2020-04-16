/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

import "./analytics.js"
import "./custom.js"
import sdk from "./web_modules/fission-sdk.js"

import * as fs from "./fs.js"
import * as ipfs from "./ipfs.js"
import * as media from "./media.js"



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


// FFS
// ---

const fsSendList = a => results => {
  app.ports.ipfsGotDirectoryList.send({
    pathSegments: a.pathSegments,
    results
  })
}


app.ports.fsAddContent.subscribe(a => {
  fs
    .add(a)
    .then( fsSendList(a) )
    .catch( reportFileSystemError )
})


app.ports.fsCreateDirectory.subscribe(a => {
  fs
    .createDirecory(a)
    .then( fsSendList({ pathSegments: a.pathSegments.slice(0, -1) }) )
    .catch( reportFileSystemError )
})


app.ports.fsListDirectory.subscribe(a => {
  fs
    .listDirectory(a)
    .then( fsSendList(a) )
    .catch( reportFileSystemError )
})


app.ports.fsLoad.subscribe(a => {
  fs
    .load(a)
    .then( fsSendList(a) )
    .catch( reportFileSystemError )
})


// Fission
// -------


// TODO: Remove
window.sdk = sdk


app.ports.checkIfUsernameIsAvailable.subscribe(async username => {
  if (sdk.user.isUsernameValid(username)) {
    const isAvailable = await sdk.user.isUsernameAvailable(username)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
})


app.ports.createAccount.subscribe(async userProps => {
  const response = await sdk.user.createAccount(userProps, "http://localhost:1337")
  const dnsLink = `${userProps.username}.fission.name`

  if (response.status < 300) {
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
    // TODO: Get error from response
    app.ports.gotCreateAccountFailure.send("Already created an account")

  }
})


// IPFS
// ----

app.ports.ipfsListDirectory.subscribe(({ address, pathSegments }) => {
  ipfs.listDirectory(address)
    .then(results => app.ports.ipfsGotDirectoryList.send({ pathSegments, results }))
    .catch(reportIpfsError)
})


// app.ports.ipfsPrefetchTree.subscribe(address => {
//   ipfs.prefetchTree(address)
// })


app.ports.ipfsResolveAddress.subscribe(async address => {
  const resolvedResult = await ipfs.replaceDnsLinkInAddress(address)
  app.ports.ipfsGotResolvedAddress.send(resolvedResult)
})


app.ports.ipfsSetup.subscribe(_ => {
  ipfs.setup()
    .then(app.ports.ipfsCompletedSetup.send)
    .catch(reportIpfsError)
})



// 🛠
// -

function authenticated() {
  const stored = localStorage.getItem("fissionDrive.authlink")
  return stored ? { dnsLink: stored } : null
}


function reportFileSystemError(err) {
  // TODO: app.ports.ipfsGotError.send(err.message || err)
  console.error(err)
}


function reportIpfsError(err) {
  app.ports.ipfsGotError.send(err.message || err)
  console.error(err)
}


function foundation() {
  const stored = localStorage.getItem("fissionDrive.foundation")
  return stored ? JSON.parse(stored) : null
}
