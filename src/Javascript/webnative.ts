import * as FissionAuthWithWnfs from "webnative/components/auth/implementation/fission-wnfs"
import * as FissionLobby from "webnative/components/capabilities/implementation/fission-lobby"
import * as FissionReference from "webnative/components/reference/implementation/fission-base"
import * as IpfsBase from "webnative/components/depot/implementation/ipfs"

import * as Ipfs from "webnative/components/depot/implementation/ipfs/index"
import * as Webnative from "webnative"

import { Configuration, namespace } from "webnative"
import { Endpoints } from "webnative/common/fission"

import * as DriveIpfs from "./ipfs.js"
import { Components } from "webnative/components.js"


// 🍱


export const PERMISSIONS = {
  app: {
    name: "Drive",
    creator: "Fission"
  },

  fs: {
    private: [ Webnative.path.root() ],
    public: [ Webnative.path.root() ]
  }
}



// 🏔


export const CONFIG: Configuration = {
  namespace: `drive-${globalThis.DATA_ROOT_DOMAIN}`,
  debug: true,

  fileSystem: {
    loadImmediately: false,
  },

  permissions: PERMISSIONS,

  userMessages: {
    versionMismatch: {
      newer: async version => alert(`Your auth lobby is outdated. It might be cached. Try reloading the page until this message disappears.\n\nIf this doesn't help, please contact support@fission.codes.\n\n(Filesystem version: ${version}. Webnative version: ${Webnative.VERSION})`),
      older: async version => alert(`Your filesystem is outdated.\n\nPlease upgrade your filesystem by running a miration (https://guide.fission.codes/accounts/account-signup/account-migration) or click on "remove this device" and create a new account.\n\n(Filesystem version: ${version}. Webnative version: ${Webnative.VERSION})`),
    }
  }
}


export const ENDPOINTS: Endpoints = {
  apiPath: "/v2/api",
  lobby: globalThis.LOBBY,
  server: globalThis.API_ENDPOINT,
  userDomain: globalThis.DATA_ROOT_DOMAIN
}



// 🛠


export async function program(): Promise<Webnative.Program> {
  const crypto = await Webnative.defaultCryptoComponent(CONFIG)
  const storage = Webnative.defaultStorageComponent(CONFIG)

  // Depot
  const { ipfs, repo } = await Ipfs.nodeWithPkg(
    { storage },
    await Ipfs.pkgFromCDN(Ipfs.DEFAULT_CDN_URL),
    `${ENDPOINTS.server}/ipfs/peers`,
    `${namespace(CONFIG)}/ipfs`,
    false
  )

  const depot = await IpfsBase.implementation(async () => ({ ipfs, repo }))

  DriveIpfs.setInstance(ipfs)

  // Manners
  const manners = Webnative.defaultMannersComponent(CONFIG)

  // Remaining
  const capabilities = FissionLobby.implementation(ENDPOINTS, { crypto, depot })
  const reference = await FissionReference.implementation(ENDPOINTS, { crypto, manners, storage })
  const auth = FissionAuthWithWnfs.implementation(ENDPOINTS, { crypto, reference, storage })

  // Fin
  const components: Components = {
    auth,
    capabilities,
    crypto,
    depot,
    manners,
    reference,
    storage,
  }

  return Webnative.assemble(CONFIG, components)
}