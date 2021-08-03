module.exports = {
  cacheId: "UNIX_TIMESTAMP",
  globDirectory: "build/",
  globPatterns: [ "**/*" ],
  inlineWorkboxRuntime: true,
  maximumFileSizeToCacheInBytes: 5000000,
  navigateFallback: "index.html",
  runtimeCaching: [
    {
      urlPattern: /^https:\/\/cdnjs\./,
      handler: "StaleWhileRevalidate"
    }
  ],
  skipWaiting: true,
  sourcemap: false,
  swDest: "build/service-worker.js",
};
