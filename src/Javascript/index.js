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
    rootCid: queryParams.get("cid") || "QmdPqtqMZ4h8SJNwBeJWNYcHQTeECdTtm56SuTqBn6dLZs"
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
