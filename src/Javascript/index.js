/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

import "./web_modules/tocca.js"
import "./web_modules/webnative/index.umd.min.js"
import "./web_modules/webnative-elm.js"

import "./custom.js"
import "./media.js"

import * as analytics from "./analytics.js"
import * as fs from "./fs.js"
import * as ipfs from "./ipfs.js"


// | (• ◡•)| (❍ᴥ❍ʋ)

const wn = webnative

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
    private: [ wn.path.root() ],
    public: [ wn.path.root() ]
  }
}



// 🚀


const app = Elm.Main.init({
  flags: {
    apiEndpoint: API_ENDPOINT,
    currentTime: Date.now(),
    usersDomain: DATA_ROOT_DOMAIN,
    viewportSize: { height: window.innerHeight, width: window.innerWidth }
  }
})


app.ports.copyToClipboard.subscribe(copyToClipboard)
app.ports.deauthenticate.subscribe(deauthenticate)
app.ports.fsDownloadItem.subscribe(fs.downloadItem)
app.ports.showNotification.subscribe(showNotification)


app.ports.fsShareItem.subscribe(args => {
  fs.shareItem(args).then(shareLink => {
    app.ports.fsGotShareLink.send(shareLink)
  }).catch(err => {
    app.ports.fsGotShareError.send(err.message || err.toString())
  })
})


app.ports.redirectToLobby.subscribe(() => {
  wn.redirectToLobby(PERMISSIONS, location.origin + location.pathname)
})


exe("fsAddContent", "add")
exe("fsFollowItem", "followItem")
exe("fsListDirectory", "listDirectory")
exe("fsListPublicDirectory", "listPublicDirectory")
exe("fsMoveItem", "moveItem")
exe("fsRemoveItem", "removeItem")


registerServiceWorker({
  path: "service-worker.js",
  onUpdateAvailable: () => {
    console.log("⚙️ Application update available")
    app.ports.appUpdateAvailable.send(null)
  },
  onUpdateFinished: () => {
    console.log("⚙️ Application update finished")
    app.ports.appUpdateFinished.send(null)
  },
})


wn.initialise({
    loadFileSystem: false,
    permissions: PERMISSIONS
  })
  .then(async state => {
    const { authenticated, newUser, permissions, throughLobby, username } = state

    // Initialise app, pt. deux
    app.ports.initialise.send(
      authenticated ? { newUser, throughLobby, username } : null
    )

    // Initialise app, pt. trois
    const fsInstance = authenticated
      ? await wn.loadFileSystem(PERMISSIONS)
      : null

    fs.setInstance(fsInstance)
    ipfs.setInstance(await wn.ipfs.get())

    window.fs = fsInstance

    app.ports.ready.send(null)

    webnativeElm.setup({
      app,
      getFs: () => fsInstance,
      webnative: wn
    })

    // Other things
    analytics.setupOnFissionCodes()

  }).catch(err => {
    console.error(err)

    if (err.toString() === "OperationError") {
      location.search = ""
    } else {
      app.ports.gotInitialisationError.send(err)
    }

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
    let args = { ...a, ...options }

    try {
      const feedback = (await fs[method](args)) || {}
      if (!feedback.results) return

      const path = feedback.path || args.path

      app.ports.fsGotDirectoryList.send({
        ...feedback,
        path: fs.removePrivatePrefix(path),
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


function registerServiceWorker({ onUpdateAvailable, onUpdateFinished, path }) {
  if (!path) throw new Error("Missing required `path` parameter")

  if ("serviceWorker" in navigator) {
    return navigator.serviceWorker.register("service-worker.js").then(registration => {
      registration.onupdatefound = () => {
        const i = registration.installing
        if (!i) return

        onUpdateAvailable()

        i.onstatechange = () => {
          if (i.state === "installed") onUpdateFinished()
        }
      }
    })
  }

  return Promise.reject("Service workers are not supported in this browser")
}
