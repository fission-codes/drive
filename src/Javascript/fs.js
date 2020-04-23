/*

(づ｡◕‿‿◕｡)づ

Everything involving the Fission File System.

*/

import "./web_modules/it-to-stream.js"
import sdk from "./web_modules/fission-sdk.js"

import * as api from "./api.js"


let ffs



// 🛠


export async function add({ blobs, pathSegments }) {
  const path = prefixedPath(pathSegments)

  await Promise.all(blobs.map(async ({ name, url }) => {
    const fileOrBlob = await fetch(url).then(r => r.blob())
    const blob = fileOrBlob.name ? fileOrBlob.slice(0, undefined, fileOrBlob.type) : fileOrBlob
    await ffs.add(`${path}/${name}`, blob)
  }))

  return await listDirectory({ pathSegments })
}


export async function addSampleData() {
  // TODO: We should maintain some dnslink with a standard set of data,
  //       and then "import" that data here.
  await ffs.mkdir("private/Apps")
  await ffs.mkdir("private/Audio")
  await ffs.mkdir("private/Documents")
  await ffs.mkdir("private/Photos")
  await ffs.mkdir("private/Video")
}


export async function createDirecory({ pathSegments }) {
  const path = prefixedPath(pathSegments)
  await ffs.mkdir(path)
  return await listDirectory({ pathSegments: pathSegments.slice(0, -1) })
}


export async function cid() {
  return (await ffs.sync()).toString()
}


export async function createNew() {
  ffs = await sdk.ffs.default.empty()
}


export async function listDirectory({ pathSegments }) {
  const isListingRoot = pathSegments.length === 0

  let path = prefixedPath(pathSegments)

  // Make a list
  const rawList = await (async _ => {
    try {
      return Object.values(await ffs.ls(path))
    } catch (err) {
      // We get an error if try to list a file.
      // This a way around that issue.
      const bananaSplit = path.split("/")
      const dir = bananaSplit.slice(0, -1).join("/")
      const file = bananaSplit[bananaSplit.length - 1]

      path = dir

      return Object.values(await ffs.ls(dir)).filter(l => {
        return l.name === file
      })
    }
  })()

  // Adjust list
  const list = rawList.map(l => ({
    ...l,
    path: `${path}/${l.name}`,
    size: l.size || 0,
    type: l.isFile ? "file" : "dir"
  }))

  // Add a fictional "public" directory when listing the "root"
  if (isListingRoot) {
    const publicCid = await ffs.publicTree.put()

    return [
      {
        name: "public",
        cid: publicCid,
        path: `${publicCid}/public}`,
        size: 0,
        type: "dir"
      },

      ...list
    ]
  }

  // Default return
  return list
}


export async function load({ cid, pathSegments, syncHook }) {
  ffs = await sdk.ffs.default.fromCID(cid)
  ffs = ffs || await sdk.ffs.default.upgradePublicCID(cid)

  if (ffs) {
    ffs.addSyncHook(syncHook)

    return await listDirectory({ pathSegments })
  } else {
    throw "Not a Fission File System"
  }
}


export async function removeItem({ pathSegments }) {
  const path = prefixedPath(pathSegments)

  await ffs.runOnTree(path, false, (tree, relPath) => {
    console.log(tree, relPath)
    return tree.rmLink(relPath)
  })

  await ffs.sync()

  return await listDirectory({ pathSegments: pathSegments.slice(0, -1) })
}


export async function updateRoot() {
  await sdk.user.updateRoot(ffs, api.endpoint)
}



// STREAMING


export function fakeStream(address, options) {
  const a = fakeStreamIterator(address, options)
  const b = itToStream.readable(a)
  return b
}


function fakeStreamIterator(address, options) {
  return { async *[Symbol.asyncIterator]() {
    const typedArray = await ffs.cat(address)
    const size = typedArray.length
    const start = options.offset || 0
    const end = options.length ? start + options.length : size - 1

    yield typedArray.slice(start, end)
  }}
}



// ⚗️


/* Drive doesn't show a "private" root directory, only a "public" one.
   So we need to prefix with "private" when necessary.
*/
function prefixedPath(pathSegments) {
  return isPrefixSegment( pathSegments[0] )
    ? pathSegments.join("/")
    : [ "private", ...pathSegments ].join("/")
}


function isPrefixSegment(s) {
  return s === "public" || s === "private"
}
