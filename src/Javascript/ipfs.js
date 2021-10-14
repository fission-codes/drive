/*

| (• ◡•)| (❍ᴥ❍ʋ)

Everything involving IPFS.

*/

import "./web_modules/it-to-stream.min.js"


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
