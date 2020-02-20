/*

| (• ◡•)| (❍ᴥ❍ʋ)

Everything involving IPFS.

*/

import "./web_modules/it-to-stream.js"
import getIpfs from "./web_modules/get-ipfs.js"


let ipfs


// 🏔


const PEER_WSS = "/dns4/node.fission.systems/tcp/4003/wss/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
const PEER_TCP = "/ip4/3.215.160.238/tcp/4001/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"



// 🛠


export async function listDirectory(address) {
  const result = await ipfs.ls(address)

  // if good old array
  if (Array.isArray(result)) {
    return result
  }

  // if async iterable
  const array = []

  for await (const file of result) {
    array.push(file)
  }

  return array
}


export async function setup() {
  ipfs = await getIpfs({
    permissions: [
      "cat",
      "files.catPullStream",
      "id",
      "ls",
      "swarm.connect",
      "version",
    ],

    browserPeers: [ PEER_WSS ],
    localPeers: [ PEER_TCP ],
    jsIpfs: "./web_modules/ipfs.js"
  })

  window.ipfs = ipfs
  return null
}


export function stream(cid, opts) {
  return ipfs.catReadableStream
    ? ipfs.catReadableStream(cid, opts)
    : ipfs.files.catReadableStream
      ? ipfs.files.catReadableStream(cid, opts)
      : itToStream.readable(ipfs.cat(cid, opts))
}
