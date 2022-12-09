import { NodeGlobalsPolyfillPlugin } from "@esbuild-plugins/node-globals-polyfill"
import { defineConfig } from "tsup"


export default defineConfig({
  esbuildPlugins: [
    NodeGlobalsPolyfillPlugin({
      buffer: true
    })
  ],
})