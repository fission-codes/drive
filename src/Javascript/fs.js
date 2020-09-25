/*

(づ｡◕‿‿◕｡)づ

Everything involving the Fission File System.

*/

import "./web_modules/it-to-stream.js"
import * as wn from "./web_modules/webnative.js"


let fs


// 🚀


export function setInstance(fileSystem) {
  fs = fileSystem
}



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

  await fs.publish()

  return await listDirectory({ pathSegments })
}


export async function createDirecory({ pathSegments }) {
  const path = prefixedPath(pathSegments)
  await fs.mkdir(path)
  await fs.publish()
  return await listDirectory({ pathSegments: pathSegments.slice(0, -1) })
}


export async function cid() {
  return (await fs.publish()).toString()
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
    cid: l.cid || l.pointer,
    path: `${path}/${l.name}`,
    size: l.size || 0,
    type: l.isFile ? "file" : "dir"
  }))

  // Add a fictional "public" directory when listing the "root"
  // (ie. the "root" = "/private")
  if (isListingRoot) {
    const publicCid = fs.root.links.public
      ? fs.root.links.public.cid
      : await fs.publicTree.put()

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


export async function removeItem({ pathSegments }) {
  const path = prefixedPath(pathSegments)
  await fs.rm(path)
  await fs.publish()
  return await listDirectory({ pathSegments: removePrivatePrefix(pathSegments).slice(0, -1) })
}


export async function moveItem({ currentPathSegments, pathSegments }) {
  const currentPath = prefixedPath(currentPathSegments)
  const newPath = prefixedPath(pathSegments)

  await fs.mv(currentPath, newPath)
  await fs.publish()
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
