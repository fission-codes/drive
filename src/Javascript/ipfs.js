/*

| (• ◡•)| (❍ᴥ❍ʋ)

Everything involving IPFS.

*/

import "./web_modules/ipfs.js"


let ipfs


// 🏔

const PEER_WSS = "/dns4/ipfs.runfission.com/tcp/4003/wss/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
const PEER_TCP = "/ip4/3.215.160.238/tcp/4001/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
const LOCAL_TCP = "/ip4/127.0.0.1/tcp/0"



// 🛠


export async function listDirectory(address) {
  return await ipfs.ls(address)
}


export async function setup() {
  ipfs = await Ipfs.create({
    config: { Addresses: { Swarm: [ LOCAL_TCP, PEER_WSS ] }}
  })

  window.ipfs = ipfs
  return null
}


export function stream(cid, opts) {
  return ipfs.catReadableStream(cid, opts)
}
