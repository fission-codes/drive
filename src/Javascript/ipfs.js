/*

| (• ◡•)| (❍ᴥ❍ʋ)

Everything involving IPFS.

*/

import "./web_modules/is-ipfs.js"
import "./web_modules/it-to-stream.js"
import sdk from "./web_modules/fission-sdk.js"

import * as endpoints from "./endpoints.js"


let ipfs



// 🛠


export async function listDirectory(address) {
  const result = await ensureArray(await ipfs.ls(address))

  if (result.length === 0) {
    const context = await ensureArray(await ipfs.get(address))
    if (!context[0] || context[0].type !== "file") return []
    return context.map(stringifyCids)
  }

  return result.map(stringifyCids)
}


export async function replaceDnsLinkInAddress(address) {
  const splitted = address.replace(/(^\/|\/$)/m, "").split("/")
  const firstPart = splitted[0]

  const isDnsLink = !IsIpfs.cid(firstPart)
  const cleanedPart = firstPart.includes(".") ? firstPart : `${firstPart}.${endpoints.users}`
  const replacedPart = isDnsLink ? await lookupDns(cleanedPart) : firstPart

  return {
    isDnsLink,
    resolved: replacedPart && [replacedPart].concat(splitted.slice(1)).join("/"),
    unresolved: isDnsLink ? [cleanedPart].concat(splitted.slice(1)).join("/") : address
  }
}


export async function setup() {
  ipfs = await sdk.ipfs.getIpfs({
    permissions: [
      "cat",
      "dag.tree",
      "files.catPullStream",
      "files.catReadableStream",
      "id",
      "ls",
      "swarm.connect",
      "version",
    ],

    jsIpfs: "./web_modules/ipfs.min.js"
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


function stringifyCids(listItem) {
  return {
    ...listItem,
    cid: listItem.cid.toString()
  }
}


async function ensureArray(result) {
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


async function lookupDns(domain) {
  try {
    return await sdk.dns.lookupDnsLink(domain)

  } catch (err) {
    return null

  }
}
