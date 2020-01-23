/*

██████╗ ██████╗ ██╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║   ██║██╔════╝
██║  ██║██████╔╝██║██║   ██║█████╗
██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝
██████╔╝██║  ██║██║ ╚████╔╝ ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝

*/

// import getIpfs from "./web_modules/get-ipfs.js"
import "./web_modules/ipfs.js"


const app = Elm.Main.init({
  node: document.getElementById("elm"),
  flags: {}
})



// IPFS
// ----

const PEER_WSS = "/dns4/ipfs.runfission.com/tcp/4003/wss/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
const PEER_TCP = "/ip4/3.215.160.238/tcp/4001/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"

let ipfs


Promise.resolve(
  Ipfs.create({
    config: { Addresses: { Swarm: [ PEER_WSS ] }}
  })

).then(i => {
  ipfs = i
  window.ipfs = i

}).then(_ => {
  listDirectory("QmdPqtqMZ4h8SJNwBeJWNYcHQTeECdTtm56SuTqBn6dLZs")

})


async function listDirectory(address) {
  console.log(await ipfs.id())

  console.log(`ipfs.dag.get(\"${address}\")`)
  const result = await ipfs.dag.get(address)

  console.log(
    result.value.Links.map(l => (
      { name: l.Name, size: l.Tsize, hash: l.Hash.toString() }
    ))
  )
}


// app.ports.listDirectory.subscribe(listDirectory)
