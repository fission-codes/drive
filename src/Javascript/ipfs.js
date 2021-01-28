/*

| (• ◡•)| (❍ᴥ❍ʋ)

Everything involving IPFS.

*/

import "./web_modules/it-to-stream.min.js"
import * as wn from "./web_modules/webnative.js"


let ipfs


// 🛠


export function setInstance(i) {
  ipfs = i
}


export function stream(address, opts) {
  console.log(address)
  const a = ipfs.cat(address, opts)
  return itToStream.readable(a)
}
