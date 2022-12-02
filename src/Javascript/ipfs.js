/*

| (• ◡•)| (❍ᴥ❍ʋ)

Everything involving IPFS.

*/

import itToStream from "it-to-stream"


let ipfs


// 🛠


export function setInstance(i) {
  ipfs = i
}


export function stream(address, opts) {
  const a = ipfs.cat(address, opts)
  return itToStream.readable(a)
}
