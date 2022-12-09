/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

// @ts-ignore
import * as TaskPort from "elm-taskport"
import * as webnativeElm from "webnative-elm"
import * as wn from "webnative"

import "tocca"

import "./custom.js"
import "./media.js"

import * as analytics from "./analytics.js"
import * as fs from "./fs.js"
import * as Webnative from "./webnative.js"


// | (• ◡•)| (❍ᴥ❍ʋ)


globalThis.wn = wn



// 🚀


let program: wn.Program | null = null


TaskPort.install()


const app = globalThis.Elm.Main.init({
  flags: {
    apiEndpoint: globalThis.API_ENDPOINT,
    currentTime: Date.now(),
    usersDomain: globalThis.DATA_ROOT_DOMAIN,
    viewportSize: { height: window.innerHeight, width: window.innerWidth }
  }
})


app.ports.blurActiveElement.subscribe(blurActiveElement)
app.ports.copyToClipboard.subscribe(copyToClipboard)
app.ports.deauthenticate.subscribe(deauthenticate)
app.ports.fsDownloadItem.subscribe(fs.downloadItem)
app.ports.showNotification.subscribe(showNotification)


app.ports.fsShareItem.subscribe(args => {
  if (!program) {
    console.error("Webnative Program not available.")
    return
  }

  fs.shareItem(args, program).then(shareLink => {
    app.ports.fsGotShareLink.send(shareLink)
  }).catch(err => {
    app.ports.fsGotShareError.send(err.message || err.toString())
  })
})


app.ports.redirectToLobby.subscribe(() => {
  program?.capabilities.request()
})


exe("fsAddContent", "add")
exe("fsListDirectory", "listDirectory")
exe("fsListPublicDirectory", "listPublicDirectory")
exe("fsMoveItem", "moveItem")
exe("fsRemoveItem", "removeItem")
exe("fsResolveItem", "resolveItem")


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


Webnative
  .program()
  .then(async prog => {
    program = prog

    const { session } = program

    // Initialise app, pt. deux
    app.ports.initialise.send(
      session ? { username: session.username } : null
    )

    // Initialise app, pt. trois
    const fsInstance = session
      ? await program.loadFileSystem(session.username)
      : null

    if (fsInstance) fs.setInstance(fsInstance)
    globalThis.fs = fsInstance

    app.ports.ready.send({
      fileSystem: fsInstance ? webnativeElm.fileSystemRef(fsInstance) : null,
      program: webnativeElm.programRef(program)
    })

    webnativeElm.init({
      fileSystems: fsInstance ? [ fsInstance ] : [],
      programs: [ program ],
      TaskPort
    })

    // Other things
    analytics.setupOnFissionCodes()

  }).catch(err => {
    if (!err) return
    console.error(err)

    if (err.toString() === "OperationError") {
      location.search = ""
    } else {
      app.ports.gotInitialisationError.send(err.toString())
    }

  })



// Ports
// =====

function blurActiveElement() {
  // @ts-ignore
  if (document.activeElement) document.activeElement.blur()
}


function copyToClipboard(text) {
  // Insert a textarea element
  const el = document.createElement("textarea")

  el.value = text
  el.setAttribute("readonly", "")
  el.style.position = "absolute"
  el.style.left = "-9999px"

  document.body.appendChild(el)

  // Store original selection
  const selection = document.getSelection()
  if (!selection) return

  const selected = selection.rangeCount > 0
    ? selection.getRangeAt(0)
    : false

  // Select & copy the text
  el.select()
  document.execCommand("copy")

  // Remove textarea element
  document.body.removeChild(el)

  // Restore original selection
  if (selected) {
    selection.removeAllRanges()
    selection.addRange(selected)
  }
}


async function deauthenticate() {
  const session = await program?.auth.session()
  if (session) session.destroy()
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
  app.ports[ port ].subscribe(async a => {
    let args = { ...a, ...options }

    try {
      const feedback = (await fs[ method ](args, program)) || {}
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

globalThis.tocca({
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
