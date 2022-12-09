/*

(づ｡◕‿‿◕｡)づ

Everything involving the Fission File System.

*/

import * as wn from "webnative"
import { DistinctivePath, FilePath } from "webnative/path/index"

import itAll from "it-all"
import itToStream from "it-to-stream"

import * as DriveIpfs from "./ipfs.js"
import { shareLink } from "webnative/components/auth/implementation/fission/index"
import { ENDPOINTS } from "./webnative.js"


let fs: wn.FileSystem


// 🚀


export function setInstance(fileSystem: wn.FileSystem) {
  fs = fileSystem
}



// 🛠


export async function add({ blobs, toPath }) {
  const basePath = prefixedPath(toPath)

  await blobs.reduce(async (acc, { path, url }) => {
    await acc
    const fileOrBlob = await fetch(url).then(r => r.blob())
    const fullPath = wn.path.combine(basePath, wn.path.fromPosix(path))
    const blob = (fileOrBlob as any).name ? fileOrBlob.slice(0, undefined, fileOrBlob.type) : fileOrBlob
    await fs.add(fullPath, new Uint8Array(await blob.arrayBuffer()))
    URL.revokeObjectURL(url)
  }, Promise.resolve(null))

  await fs.publish()

  return await listDirectory({ path: toPath })
}


export async function downloadItem({ path }) {
  const ipfs = DriveIpfs.getInstance()
  const [ isIpfsPath, pathWithPrefix ] =
    wn.path.isBranch(wn.path.Branch.Pretty, path)
      ? [ true, path ]
      : [ false, prefixedPath(path) ]

  const blob = new Blob([
    isIpfsPath
      ? await itAll(ipfs.cat(wn.path.toPosix(pathWithPrefix))).then(a => a[ 0 ])
      : await fs.cat(pathWithPrefix)
  ])

  const blobUrl = URL.createObjectURL(blob)

  const a = document.createElement("a")
  a.style.display = "none"
  document.body.appendChild(a)
  a.href = blobUrl
  a.download = filename(path)
  a.click()
  URL.revokeObjectURL(blobUrl)
}


export async function resolveItem({ follow, index, path }) {
  // If the symlinks resolves to a file, or follow is set to false,
  // list the parent directory and replace the symlink item with the resolved one.
  // If it resolves to a directory and follow is set to true, list that directory.

  const resolved: any = await fs.get(path)
  const name = wn.path.terminus(path)

  if (!follow || resolved.header.metadata.isFile) {
    const parentPath = wn.path.parent(path)
    const listing = await listDirectory({ path: parentPath })
    const kind = resolved.header.metadata.isFile ? "file" : "directory"
    const cid = resolved.cid || resolved.header.content || resolved.header.bareNameFilter

    return {
      ...listing,
      index,
      results: listing.results.map((l, idx) => {
        if (idx === index) return {
          name: l.name,
          cid: cid.toString(),
          isFile: resolved.header.metadata.isFile,
          path: wn.path.toPosix({ [ kind ]: wn.path.unwrap(path) } as DistinctivePath),
          size: resolved.header.metadata.size || 0,
          type: resolved.header.metadata.isFile ? "file" : "dir"
        }
        return l
      }),
      path: parentPath,
      replaceSymlink: path
    }

  } else {
    // We need to change the URL/fragment,
    // so we'll do that and that in turn will trigger a directory listing.
    self.location.href = location.hash + name + "/"

  }
}


export async function listDirectory(args) {
  const ipfs = DriveIpfs.getInstance()
  const isListingRoot = wn.path.unwrap(args.path).length === 0
  const rootCid = await fs.root.put()

  let path = prefixedPath(args.path)

  // Make a list
  let listing

  if (wn.path.isFile(path)) {
    const pathSegments = wn.path.unwrap(path)
    const dirname = pathSegments.slice(0, -1)
    const filename = pathSegments[ pathSegments.length - 1 ]

    path = { directory: dirname }

    listing = Object.values(await fs.ls(path)).filter(l => {
      return l.name === filename
    })

  } else {
    listing = Object.values(await fs.ls(path))

  }

  // Adjust list
  const readOnly = await fs.get(path).then(a => a ? (a as any).readOnly : false)
  const isListingPublic = wn.path.isBranch(wn.path.Branch.Public, path)
  const prettyIpfsPath = prefix => {
    return "/ipfs/"
      + rootCid
      + "/" + prefix + "/"
      + wn.path.toPosix({ directory: wn.path.unwrap(path).slice(1) })
  }

  let results = await Promise.all(
    listing.map(async l => {
      let cid

      if (l.ipns) {
        // Carry on

      } else if (isListingPublic) {
        try {
          cid = await ipfs.files.stat(prettyIpfsPath("p") + l.name)
          cid = cid.cid.toString()
        } catch (e) {
          try {
            cid = await ipfs.files.stat(prettyIpfsPath("pretty") + l.name)
            cid = cid.cid.toString()
          } catch (e) {
            cid = l.cid || l.pointer
          }
        }

      } else {
        cid = l.cid || l.pointer

      }

      const itemPath = wn.path.toPosix(
        // @ts-ignore
        wn.path.combine(path, { [ l.isFile ? "file" : "directory" ]: [ l.name ] })
      )

      if (l.ipns) return {
        ...l,

        path: itemPath
      }

      return {
        ...l,

        cid: cid.toString(),
        path: itemPath,
        readOnly: readOnly ? true : undefined,
        size: l.size || 0,
        type: l.isFile ? "file" : "dir"
      }
    })
  )

  // Add a fictional "public" directory when listing the "root"
  // (ie. the "root" = "/private")
  if (isListingRoot) {
    const publicCid = fs.root.links.public
      ? fs.root.links.public.cid
      : await fs.root.publicTree.put()

    results = [
      {
        name: "public",
        cid: publicCid.toString(),
        path: `${publicCid}/public`,
        readOnly: readOnly ? true : undefined,
        size: 0,
        type: "dir"
      },

      ...results
    ]
  }

  // Default return
  return {
    path,
    readOnly,
    rootCid,
    results
  }
}


/**
 * More specifically, listing other people's public filesystems.
 */
export async function listPublicDirectory({ root, path }, program: wn.Program) {
  const rootCid = await program.components.reference.dns.lookupDnsLink(root)

  if (!rootCid) throw new Error(
    "Couldn't find this filesystem"
  )

  const ipfs = DriveIpfs.getInstance()
  const prettifiedPath = prettyPath(rootCid, path)
  const stats = await ipfs.files.stat(`/ipfs/${prettifiedPath}`)
  const isFile = stats.type === "file"
  const cid = stats.cid.toString()

  const results = isFile
    ? [ {
      ...stats,
      cid: cid,
      name: filename(path),
      path: prettifiedPath
    } ]
    : Object
      .values(await ipfs.ls(cid))
      .map(a => ({ ...a, cid: a.cid.toString() }))

  return {
    rootCid,
    results
  }
}


export async function removeItem(args) {
  const path = prefixedPath(args.path)

  await fs.rm(path)
  await fs.publish()

  return await listDirectory({
    path: removePrivatePrefix(wn.path.parent(path))
  })
}


export async function moveItem({ fromPath, toPath }) {
  const from = prefixedPath(fromPath)
  const to = prefixedPath(toPath)

  await fs.mv(from, to)
  await fs.publish()

  return await listDirectory({
    path: removePrivatePrefix(wn.path.parent(to))
  })
}


export async function shareItem({ path, shareWith }, program: wn.Program) {
  return shareLink(
    ENDPOINTS,
    await fs.sharePrivate([ path ], { shareWith })
  )
}


// STREAMING


export function fakeStream(address, options) {
  const a = fakeStreamIterator(address, options)
  const b = itToStream.readable(a)
  return b
}


function fakeStreamIterator(address, options) {
  return {
    async *[ Symbol.asyncIterator ]() {
      const typedArray = await fs.cat(wn.path.fromPosix(address) as FilePath)
      const size = typedArray.length
      const start = options.offset || 0
      const end = options.length ? start + options.length : size - 1

      yield typedArray.slice(start, end)
    }
  }
}



// ⚗️


export function filename(path) {
  const unwrapped = wn.path.unwrap(path)
  return unwrapped[ unwrapped.length - 1 ]
}


/* Drive doesn't show a "private" root directory, only a "public" one.
   So we need to prefix with "private" when necessary.
*/
export function prefixedPath(path) {
  return wn.path.isBranch(wn.path.Branch.Public, path) ||
    wn.path.isBranch(wn.path.Branch.Private, path)
    ? path
    : wn.path.map(a => [ wn.path.Branch.Private, ...a ], path)
}


export function prettyPath(rootCid, path) {
  return `${rootCid}/p/${wn.path.toPosix(path)}`
}


export function removePrivatePrefix(path) {
  return wn.path.isBranch(wn.path.Branch.Private, path)
    ? wn.path.removeBranch(path)
    : path
}
