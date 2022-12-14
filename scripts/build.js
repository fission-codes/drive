import { NodeGlobalsPolyfillPlugin } from "@esbuild-plugins/node-globals-polyfill"
import esbuild from "esbuild"


await esbuild.build({
  entryPoints: [ "src/Javascript/index.ts" ],
  outdir: "build",
  bundle: true,
  splitting: true,
  minify: true,
  sourcemap: true,
  platform: "browser",
  format: "esm",
  target: "es2020",
  define: {
    "global": "globalThis",
    "globalThis.process.env.NODE_ENV": "production"
  },
  plugins: [
    NodeGlobalsPolyfillPlugin({
      buffer: true
    })
  ]
})