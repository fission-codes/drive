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
  return ipfs.catReadableStream
    ? ipfs.catReadableStream(address, opts)
    : ipfs.files.catReadableStream
      ? ipfs.files.catReadableStream(address, opts)
      : itToStream.readable(ipfs.cat(address, opts))
}
