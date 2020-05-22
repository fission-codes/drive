/*

(づ｡◕‿‿◕｡)づ

Everything involving the Fission File System.

*/

import "./web_modules/it-to-stream.js"
import sdk from "./web_modules/fission-sdk.js"

import * as api from "./api.js"


let fs



// 🛠


export async function add({ blobs, pathSegments }) {
  const basePath = prefixedPath(pathSegments)

  await blobs.reduce(async (acc, { path, url }) => {
    await acc
    const fileOrBlob = await fetch(url).then(r => r.blob())
    const fullPath = (basePath.length ? basePath + "/" : "") + path
    const blob = fileOrBlob.name ? fileOrBlob.slice(0, undefined, fileOrBlob.type) : fileOrBlob
    await fs.add(fullPath, blob)
    URL.revokeObjectURL(url)
  }, Promise.resolve(null))

  return await listDirectory({ pathSegments })
}


export async function addSampleData() {
  // TODO: We should maintain some dnslink with a standard set of data,
  //       and then "import" that data here.
  await fs.mkdir("private/Audio")
  await fs.mkdir("private/Documents")
  await fs.mkdir("private/Photos")
  await fs.mkdir("private/Video")
}


export async function createDirecory({ pathSegments }) {
  const path = prefixedPath(pathSegments)
  await fs.mkdir(path)
  return await listDirectory({ pathSegments: pathSegments.slice(0, -1) })
}


export async function cid() {
  return (await fs.sync()).toString()
}


export async function createNew() {
  fs = await sdk.fs.empty()
}


export async function listDirectory({ pathSegments }) {
  const isListingRoot = pathSegments.length === 0

  let path = prefixedPath(pathSegments)

  // Make a list
  const rawList = await (async _ => {
    try {
      return Object.values(await fs.ls(path))
    } catch (err) {
      // We get an error if try to list a file.
      // This a way around that issue.
      const bananaSplit = path.split("/")
      const dir = bananaSplit.slice(0, -1).join("/")
      const file = bananaSplit[bananaSplit.length - 1]

      path = dir

      return Object.values(await fs.ls(dir)).filter(l => {
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
    const publicCid = await fs.publicTree.put()

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
  fs = await sdk.fs.fromCID(cid)
  fs = fs || await sdk.fs.upgradePublicCID(cid)

  if (fs) {
    fs.addSyncHook(syncHook)
    return await listDirectory({ pathSegments })
  } else {
    throw "Not a Fission File System"
  }
}


export async function removeItem({ pathSegments }) {
  const path = prefixedPath(pathSegments)
  await fs.rm(path)
  return await listDirectory({ pathSegments: removePrivatePrefix(pathSegments).slice(0, -1) })
}


export async function updateRoot() {
  await sdk.user.updateRoot({
    apiEndpoint: api.endpoint,
    authUcan: "TODO",
    fileSystem: fs
  })
}



// STREAMING


export function fakeStream(address, options) {
  const a = fakeStreamIterator(address, options)
  const b = itToStream.readable(a)
  return b
}


function fakeStreamIterator(address, options) {
  return { async *[Symbol.asyncIterator]() {
    const typedArray = await fs.cat(address)
    const size = typedArray.length
    const start = options.offset || 0
    const end = options.length ? start + options.length : size - 1

    yield typedArray.slice(start, end)
  }}
}



// ⚗️


export function isPrefixSegment(s) {
  return s === "public" || s === "private"
}


/* Drive doesn't show a "private" root directory, only a "public" one.
   So we need to prefix with "private" when necessary.
*/
export function prefixedPath(pathSegments) {
  return isPrefixSegment( pathSegments[0] )
    ? pathSegments.join("/")
    : [ "private", ...pathSegments ].join("/")
}


export function removePrivatePrefix(pathSegments) {
  return pathSegments[0] === "private"
    ? pathSegments.slice(1)
    : pathSegments
}
