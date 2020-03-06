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


export async function replaceDnsLinkInAddress(address) {
  const splitted = address.replace(/(^\/|\/$)/m, "").split("/")
  const firstPart = splitted[0]

  const isDnsLink = !firstPart.startsWith("Qm") && !firstPart.startsWith("bafy")
  const cleanedPart = firstPart.includes(".") ? firstPart : `${firstPart}.fission.name`
  const replacedPart = isDnsLink ? await lookupDns(cleanedPart) : firstPart

  return {
    isDnsLink,
    resolved: [replacedPart].concat(splitted.slice(1)).join("/"),
    unresolved: isDnsLink ? [cleanedPart].concat(splitted.slice(1)).join("/") : address
  }
}


export async function setup() {
  const isSafari =
    /^((?!chrome|android).)*safari/i.test(navigator.userAgent)

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
    jsIpfs: isSafari
      ? "https://unpkg.com/ipfs@0.40.0/dist/index.min.js"
      : "./web_modules/ipfs.js"
  })

  window.ipfs = ipfs
  return null
}


export function stream(address, opts) {
  return ipfs.catReadableStream
    ? ipfs.catReadableStream(address, opts)
    : ipfs.files.catReadableStream
      ? ipfs.files.catReadableStream(address, opts)
      : itToStream.readable(ipfs.cat(address, opts))
}



// ㊙️


async function lookupDns(domain) {
  try {
    const result = await ipfs.dns(domain)
    return result.replace(/^\/ipfs\//, "")

  } catch (_) {
    return domain

  }
}
