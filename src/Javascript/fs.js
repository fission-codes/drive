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


export async function downloadItem({ pathSegments }) {
  const [ isIpfsPath, path ] =
    pathSegments[1] === "pretty"
      ? [ true, pathSegments.join("/") ]
      : [ false, prefixedPath(pathSegments) ]

  const blob = new Blob([
    isIpfsPath
      ? await wn.ipfs.catBuf(path)
      : await fs.cat(path)
  ])

  const blobUrl = URL.createObjectURL(blob)

  const a = document.createElement("a")
  a.style = "display: none"
  document.body.appendChild(a)
  a.href = blobUrl
  a.download = pathSegments[pathSegments.length - 1]
  a.click()
  URL.revokeObjectURL(blobUrl)
}


export async function listDirectory({ pathSegments }) {
  const isListingRoot = pathSegments.length === 0

  let path = prefixedPath(pathSegments)

  // Make a list
  const rawList = await (async _ => {
    try {
      return Object.values(await fs.ls(path))

    } catch (err) {
      if (err.message === "Can not `ls` a file") {
        // We get an error if try to list a file.
        // This a way around that issue.
        const bananaSplit = path.split("/")
        const dir = bananaSplit.slice(0, -1).join("/")
        const file = bananaSplit[bananaSplit.length - 1]

        path = dir

        return Object.values(await fs.ls(dir)).filter(l => {
          return l.name === file
        })
      } else {
        throw err
      }

    }
  })()

  // Adjust list
  let results = rawList.map(l => ({
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

    results = [
      {
        name: "public",
        cid: publicCid,
        path: `${publicCid}/public}`,
        size: 0,
        type: "dir"
      },

      ...results
    ]
  }

  // Default return
  return {
    rootCid: await fs.root.put(),
    results
  }
}


/**
 * More specifically, listing other people's public filesystems.
 */
export async function listPublicDirectory({ root, pathSegments }) {
  const rootCid = await wn.dns.lookupDnsLink(root)

  if (!rootCid) throw new Error(
    "Couldn't find this filesystem"
  )

  const ipfs = await wn.ipfs.get()
  const path = `${rootCid}/pretty/${pathSegments.join("/")}`
  const stats = await ipfs.files.stat(`/ipfs/${path}`)
  const isFile = stats.type === "file"

  const results = isFile
    ? [{
        ...stats,
        cid: stats.cid.toString(),
        name: pathSegments[pathSegments.length - 1],
        path
      }]
    : Object
        .values(await wn.ipfs.ls(path))
        .map(a => ({ ...a, cid: a.cid.toString() }))

  return {
    rootCid,
    results
  }
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
