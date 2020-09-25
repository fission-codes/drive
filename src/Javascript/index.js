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

import "./custom.js"

import * as analytics from "./analytics.js"
import * as fs from "./fs.js"
import * as media from "./media.js"
import { throttle } from "./common.js"
import { setup } from "./sdk.js"


// | (• ◡•)| (❍ᴥ❍ʋ)


self.wn = wn


wn.setup.endpoints({
  api: API_ENDPOINT,
  lobby: LOBBY,
  user: DATA_ROOT_DOMAIN
})

wn.setup.ipfs(setup.ipfs)
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


let app


wn.initialise({ permissions: PERMISSIONS })
  .then(state => {
  const { authenticated, newUser, permissions, throughLobby, username } = state

  // File system
  fs.setInstance(state.fs)

  // Initialize app
  app = Elm.Main.init({
    node: document.getElementById("elm"),
    flags: {
      authenticated: authenticated ? { newUser, throughLobby, username } : null,
      currentTime: Date.now(),
      usersDomain: DATA_ROOT_DOMAIN,
      viewportSize: { height: window.innerHeight, width: window.innerWidth }
    }
  })

  // Ports
  app.ports.copyToClipboard.subscribe(copyToClipboard)
  app.ports.deauthenticate.subscribe(deauthenticate)
  app.ports.redirectToLobby.subscribe(() => wn.redirectToLobby(permissions))
  app.ports.renderMedia.subscribe(renderMedia)
  app.ports.showNotification.subscribe(showNotification)

  // Ports (FS)
  exe("fsAddContent", "add")
  exe("fsCreateDirectory", "createDirecory", { listParent: true })
  exe("fsListDirectory", "listDirectory")
  exe("fsMoveItem", "moveItem", { listParent: true })
  exe("fsRemoveItem", "removeItem", { listParent: true })

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
  wn.leave()
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


// FS
// --

function exe(port, method, options = {}) {
  app.ports[port].subscribe(async a => {
    let args = { pathSegments: [], ...a, ...options }
    let results

    try {
      results = await fs[method](args)

      app.ports.fsGotDirectoryList.send({
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



// 🛠
// ==

tocca({
  dbltapThreshold: 400,
  tapThreshold: 250
})


function reportFileSystemError(err) {
  console.error(err)
  app.ports.fsGotError.send(err.message || err || "")
}
