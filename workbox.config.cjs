module.exports = {
  "cacheId": "fission-suite/auth-lobby",
  "clientsClaim": true,
  "globDirectory": "build/",
  "globPatterns": [ "**/*" ],
  "inlineWorkboxRuntime": true,
  "runtimeCaching": [
    { urlPattern: /^https:\/\/cdnjs\./, handler: "StaleWhileRevalidate" },
    { urlPattern: /^http/, handler: "NetworkFirst" },
    { urlPattern: /(.*)/, handler: "NetworkFirst" }
  ],
  "skipWaiting": true,
  "swDest": "build/service-worker.js",
};
