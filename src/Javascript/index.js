/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

import * as ipfs from  "./ipfs.js"


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
  ipfs.listDirectory(cid).then(app.ports.ipfsGotDirectoryList.send)
})


app.ports.ipfsSetup.subscribe(_ => {
  ipfs.setup().then(app.ports.ipfsCompletedSetup.send)
})


app.ports.removeStoredRootCid.subscribe(_ => {
  localStorage.removeItem("fissionDrive.rootCid")
})


app.ports.storeRootCid.subscribe(cid => {
  localStorage.setItem("fissionDrive.rootCid", cid)
})
