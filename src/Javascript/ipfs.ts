/*

| (• ◡•)| (❍ᴥ❍ʋ)

Everything involving IPFS.

*/

import { IPFS } from "ipfs-core-types"
import itToStream from "it-to-stream"


let ipfs


// 🛠


export function getInstance(): IPFS {
  return ipfs
}


export function setInstance(i: IPFS) {
  ipfs = i
}


export function stream(address, opts) {
  const a = ipfs.cat(address, opts)
  return itToStream.readable(a)
}
