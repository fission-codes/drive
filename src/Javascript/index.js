/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

import "./web_modules/tocca.js"
import * as wn from "./web_modules/webnative.js"
import "./web_modules/webnative-elm.js"

import "./custom.js"
import "./media.js"

import * as analytics from "./analytics.js"
import * as fs from "./fs.js"
import * as ipfs from "./ipfs.js"


// | (• ◡•)| (❍ᴥ❍ʋ)


self.wn = wn


wn.setup.endpoints({
  api: API_ENDPOINT,
  lobby: LOBBY,
  user: DATA_ROOT_DOMAIN
})


wn.setup.debug({ enabled: true })



// 🍱


const PERMISSIONS = {
  app: {
    name: "Drive",
    creator: "Fission"
  },

  fs: {
    privatePaths: [ "/" ],
    publicPaths: [ "/" ]
  }
}



// 🚀


const app = Elm.Main.init({
  flags: {
    apiDomain: API_ENDPOINT.replace(/^https?:\/\//, ""),
    currentTime: Date.now(),
    usersDomain: DATA_ROOT_DOMAIN,
    viewportSize: { height: window.innerHeight, width: window.innerWidth }
  }
})


app.ports.copyToClipboard.subscribe(copyToClipboard)
app.ports.deauthenticate.subscribe(deauthenticate)
app.ports.showNotification.subscribe(showNotification)

app.ports.redirectToLobby.subscribe(() => {
  wn.redirectToLobby(PERMISSIONS, location.origin + location.pathname)
})

exe("fsAddContent", "add")
exe("fsListDirectory", "listDirectory")
exe("fsListPublicDirectory", "listPublicDirectory")
exe("fsMoveItem", "moveItem", { listParent: true })
exe("fsRemoveItem", "removeItem", { listParent: true })

app.ports.fsDownloadItem.subscribe(fs.downloadItem)


wn.initialise({ permissions: PERMISSIONS })
  .then(async state => {
  const { authenticated, newUser, permissions, throughLobby, username } = state

  // File system
  fs.setInstance(state.fs)
  ipfs.setInstance(await wn.ipfs.get())

  window.fs = state.fs

  // Initialise app, pt. deux
  app.ports.initialise.send(
    authenticated ? { newUser, throughLobby, username } : null
  )

  webnativeElm.setup(app, () => state.fs);

  // Other things
  analytics.setupOnFissionCodes()
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
  wn.leave({})
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


// Blur
// ----

window.addEventListener("blur", event => {
  if (app && event.target === window) app.ports.lostWindowFocus.send(null)
})


// FS
// --

function exe(port, method, options = {}) {
  app.ports[port].subscribe(async a => {
    let args = { pathSegments: [], ...a, ...options }

    try {
      const { results, rootCid } = (await fs[method](args)) || {}
      if (!results) return

      app.ports.fsGotDirectoryList.send({
        pathSegments: fs.removePrivatePrefix(
          args.pathSegments.slice(0, options.listParent ? -1 : undefined)
        ),
        results,
        rootCid
      })

    } catch (e) {
      reportFileSystemError(e)

    }
  })
}



// 🛠
// ==

tocca({
  dbltapThreshold: 400,
  tapThreshold: 250
})


function reportFileSystemError(err) {
  const msg = err.message || err || ""
  console.error(err)
  app.ports.fsGotError.send(msg)
}
